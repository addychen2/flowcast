import MapKit

@MainActor
class RouteManager: ObservableObject {
    @Published var route: MKRoute?
    @Published var region: MKCoordinateRegion
    @Published var currentNavigationStep: MKRoute.Step?
    @Published var destinationName: String?
    @Published var isNavigating: Bool = false
    @Published var shouldRecenter: Bool = false
    @Published var stepIndex: Int = 0 // Made public
    
    weak var locationManager: LocationManager?
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        
        // Initialize with a default region
        if let location = locationManager.location {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            // Will be updated when location becomes available
            self.region = MKCoordinateRegion(
                center: locationManager.locationManager.location?.coordinate ?? CLLocationCoordinate2D(),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        // Listen for location updates
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
        
        // Only update region if we're not navigating
        if !isNavigating {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        
        // Check for next step if we're navigating
        if isNavigating, let currentStep = currentNavigationStep {
            let stepCoordinate = currentStep.polyline.coordinate
            let distanceToNextStep = location.distance(from: CLLocation(latitude: stepCoordinate.latitude, longitude: stepCoordinate.longitude))
            
            if distanceToNextStep < 20 {
                nextStep()
            }
        }
    }
    
    func startNavigation() {
        // First set up the initial navigation state
        currentNavigationStep = route?.steps.first
        stepIndex = 0
        
        // Then activate navigation
        isNavigating = true
    }
    
    func endNavigation() {
        isNavigating = false
        route = nil
        currentNavigationStep = nil
        destinationName = nil
        stepIndex = 0
        shouldRecenter = false
        
        if let currentLocation = locationManager?.location {
            region = MKCoordinateRegion(
                center: currentLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    func setDestination(_ destination: MKMapItem) {
        print("Setting destination: \(destination.name ?? "Unknown")")
        destinationName = destination.name
        
        let request = MKDirections.Request()
        
        if let currentLocation = locationManager?.location {
            print("Using current location: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            let currentPlacemark = MKPlacemark(coordinate: currentLocation.coordinate)
            request.source = MKMapItem(placemark: currentPlacemark)
        } else {
            print("Warning: Current location not available, using forCurrentLocation()")
            request.source = MKMapItem.forCurrentLocation()
        }
        
        request.destination = destination
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [weak self] response, error in
            Task { @MainActor in
                if let error = error {
                    print("Error calculating route: \(error.localizedDescription)")
                    return
                }
                
                guard let route = response?.routes.first else {
                    print("No routes found")
                    return
                }
                
                print("Route calculated: \(route.steps.count) steps")
                // Don't update region if we're in navigation mode
                guard let self = self, !self.isNavigating else { return }
                
                self.route = route
                self.currentNavigationStep = route.steps.first
                self.stepIndex = 0
            }
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
