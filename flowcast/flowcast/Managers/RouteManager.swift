import MapKit

@MainActor
class RouteManager: ObservableObject {
    @Published var route: MKRoute?
    @Published var region: MKCoordinateRegion
    @Published var currentNavigationStep: MKRoute.Step?
    @Published var destinationName: String?
    @Published var isNavigating: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var stepIndex: Int = 0
    @Published var availableRoutes: [MKRoute] = []
    @Published var showRoutesSheet: Bool = false
    @Published var isCalculating: Bool = false
    @Published var error: String?
    @Published var routeError: String?
    
    weak var locationManager: LocationManager?
    private var activeDirectionsRequest: MKDirections?
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 1.0
    private var requestQueue: [(MKMapItem, @MainActor () -> Void)] = []
    private var isProcessingQueue = false
    private var retryTimer: Timer?
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        
        if let location = locationManager.location {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            self.region = MKCoordinateRegion(
                center: locationManager.locationManager.location?.coordinate ?? CLLocationCoordinate2D(),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidUpdate),
            name: .locationDidUpdate,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func locationDidUpdate(_ notification: Notification) {
        guard let location = notification.object as? CLLocation else { return }
        
        if !isNavigating {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        if isNavigating, let currentStep = currentNavigationStep {
            let stepCoordinate = currentStep.polyline.coordinate
            let distanceToNextStep = location.distance(from: CLLocation(latitude: stepCoordinate.latitude, longitude: stepCoordinate.longitude))
            
            if distanceToNextStep < 20 {
                nextStep()
            }
        }
    }
    
    private func enqueueRouteRequest(_ destination: MKMapItem, completion: @MainActor @escaping () -> Void) {
        requestQueue.append((destination, completion))
        processQueueIfNeeded()
    }
    
    private func processQueueIfNeeded() {
        guard !isProcessingQueue, let (destination, completion) = requestQueue.first else { return }
        
        isProcessingQueue = true
        setDestinationWithRetry(destination) { [weak self] success in
            guard let self = self else { return }
            
            self.requestQueue.removeFirst()
            self.isProcessingQueue = false
            
            if success {
                completion()
            }
            
            if !self.requestQueue.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.processQueueIfNeeded()
                }
            }
        }
    }
    
    func setDestination(_ destination: MKMapItem) {
        guard !isCalculating else {
            print("Route calculation already in progress")
            return
        }
        
        routeError = nil
        activeDirectionsRequest?.cancel()
        
        enqueueRouteRequest(destination) {
            // Completion if needed
        }
    }
    
    private func setDestinationWithRetry(_ destination: MKMapItem, completion: @escaping (Bool) -> Void) {
        print("Setting destination: \(destination.name ?? "Unknown")")
        destinationName = destination.name
        isCalculating = true
        error = nil
        
        let request = MKDirections.Request()
        
        guard let currentLocation = locationManager?.location else {
            Task {
                for _ in 0..<20 {
                    if let location = locationManager?.location {
                        let currentPlacemark = MKPlacemark(coordinate: location.coordinate)
                        request.source = MKMapItem(placemark: currentPlacemark)
                        await calculateRouteWithRetry(with: request, to: destination, retryCount: 3, completion: completion)
                        return
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                print("Warning: Location still not available after waiting")
                self.routeError = "Unable to get current location"
                completion(false)
            }
            return
        }
        
        print("Using current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        let currentPlacemark = MKPlacemark(coordinate: currentLocation.coordinate)
        request.source = MKMapItem(placemark: currentPlacemark)
        
        Task {
            await calculateRouteWithRetry(with: request, to: destination, retryCount: 3, completion: completion)
        }
    }
    
    private func calculateRouteWithRetry(with request: MKDirections.Request, to destination: MKMapItem, retryCount: Int, completion: @escaping (Bool) -> Void) async {
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        do {
            let routes = try await calculateRoute(with: request)
            handleSuccessfulRoutes(routes)
            completion(true)
        } catch {
            if let error = error as? NSError,
               error.domain == MKError.errorDomain,
               error.code == MKError.Code.loadingThrottled.rawValue {
                // Handle rate limiting
                if retryCount > 0 {
                    let delay = getRetryDelay(error: error)
                    print("Rate limited. Retrying in \(delay) seconds...")
                    self.routeError = "Rate limited. Retrying..."
                    
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await calculateRouteWithRetry(with: request, to: destination, retryCount: retryCount - 1, completion: completion)
                    return
                }
            }
            
            handleRouteError(error)
            completion(false)
        }
    }
    
    private func calculateRoute(with request: MKDirections.Request) async throws -> [MKRoute] {
        let directions = MKDirections(request: request)
        activeDirectionsRequest = directions
        lastRequestTime = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response {
                    continuation.resume(returning: response.routes)
                } else {
                    continuation.resume(throwing: NSError(domain: "RouteManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response received"]))
                }
            }
        }
    }
    
    private func handleSuccessfulRoutes(_ routes: [MKRoute]) {
        guard !routes.isEmpty else {
            routeError = "No routes found"
            return
        }
        
        print("Routes calculated: \(routes.count)")
        if !isNavigating {
            availableRoutes = routes
            route = routes.first
            currentNavigationStep = routes.first?.steps.first
            stepIndex = 0
            showRoutesSheet = true
        }
        
        isCalculating = false
        activeDirectionsRequest = nil
        routeError = nil
    }
    
    private func handleRouteError(_ error: Error) {
        print("Error calculating route: \(error.localizedDescription)")
        self.error = error.localizedDescription
        self.routeError = "Unable to calculate route. Please try again."
        isCalculating = false
        activeDirectionsRequest = nil
    }
    
    private func getRetryDelay(error: Error) -> Double {
        if let error = error as? NSError,
           let details = error.userInfo["details"] as? [[String: Any]],
           let firstDetail = details.first,
           let timeUntilReset = firstDetail["timeUntilReset"] as? Double {
            return min(timeUntilReset + 1, 5)
        }
        return 5
    }
    
    func selectRoute(_ route: MKRoute) {
        self.route = route
        self.currentNavigationStep = route.steps.first
        self.stepIndex = 0
        self.showRoutesSheet = false
    }
    
    func startNavigation() {
        currentNavigationStep = route?.steps.first
        stepIndex = 0
        isNavigating = true
    }
    
    func endNavigation() {
        isNavigating = false
        route = nil
        currentNavigationStep = nil
        destinationName = nil
        stepIndex = 0
        shouldRecenter = false
        availableRoutes = []
        
        if let currentLocation = locationManager?.location {
            region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func nextStep() {
        guard let route = route, stepIndex < route.steps.count - 1 else {
            print("Reached end of route")
            return
        }
        stepIndex += 1
        currentNavigationStep = route.steps[stepIndex]
        print("Moving to step \(stepIndex + 1) of \(route.steps.count): \(route.steps[stepIndex].instructions)")
    }
    
    func recenterOnUser() {
        shouldRecenter = true
    }
}
