import Foundation
import CoreLocation
import MapKit

extension MKPolyline {
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                            count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

@MainActor
class TrafficManager: ObservableObject {
    @Published var predictions: [TrafficPrediction] = []
    @Published var currentTrafficSegments: [TrafficSegment] = []
    private var timer: Timer?
    weak var locationManager: LocationManager?
    private var isGenerating = false
    private var pendingLocation: CLLocation?
    private var activeDirectionsRequests: [MKDirections] = []
    private var lastUpdateTime: Date?
    private let minimumUpdateInterval: TimeInterval = 120 // 2 minutes between updates
    private var trafficRequestQueue: [(CLLocation, () -> Void)] = []
    private var isProcessingQueue = false
    
    init(locationManager: LocationManager? = nil) {
        self.locationManager = locationManager
        generatePredictions()
        startTrafficUpdates()
    }
    
    func generatePredictions() {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.weekdaySymbols
        
        predictions = (0..<5).map { dayOffset in
            let date = Date().addingTimeInterval(TimeInterval(86400 * dayOffset))
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let dayName = dayOffset == 0 ? "Today" :
                         dayOffset == 1 ? "Tomorrow" :
                         weekdaySymbols[weekdayIndex]
            
            return TrafficPrediction(
                dayName: dayName,
                morning: generateRandomCongestion(),
                afternoon: generateRandomCongestion(),
                evening: generateRandomCongestion()
            )
        }
    }
    
    private func generateRandomCongestion() -> CongestionLevel {
        let random = Double.random(in: 0...1)
        if random < 0.3 { return .low }
        if random < 0.7 { return .moderate }
        return .heavy
    }
    
    func startTrafficUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTrafficData()
            }
        }
        updateTrafficData()
    }
    
    func updateTrafficData() {
        // Check if enough time has passed since last update
        if let lastUpdate = lastUpdateTime {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < minimumUpdateInterval {
                return
            }
        }
        
        if let location = pendingLocation {
            enqueueTrafficRequest(location)
            pendingLocation = nil
        } else if let location = locationManager?.location {
            enqueueTrafficRequest(location)
        }
    }
    
    private func enqueueTrafficRequest(_ location: CLLocation) {
        trafficRequestQueue.append((location, {}))
        processTrafficQueue()
    }
    
    private func processTrafficQueue() {
        guard !isProcessingQueue, let (location, completion) = trafficRequestQueue.first else { return }
        
        isProcessingQueue = true
        Task {
            await generateTrafficAroundLocation(location)
            
            await MainActor.run {
                self.trafficRequestQueue.removeFirst()
                self.isProcessingQueue = false
                completion()
                
                // Process next request if any, with delay
                if !self.trafficRequestQueue.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        Task { @MainActor in
                            self.processTrafficQueue()
                        }
                    }
                }
            }
        }
    }
    
    func generateTrafficForSearchedLocation(_ coordinate: CLLocationCoordinate2D) {
        // Cancel any active directions requests
        activeDirectionsRequests.forEach { $0.cancel() }
        activeDirectionsRequests.removeAll()
        
        // Set the new location as pending
        pendingLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Immediately generate traffic for the new location
        updateTrafficData()
    }
    
    private func generateTrafficAroundLocation(_ location: CLLocation) async {
        guard !isGenerating else { return }
        isGenerating = true
        
        // Reduced number of directions and distances
        let numberOfDirections = 6 // Reduced from 12
        let radiusDistances = [0.01] // Reduced from [0.005, 0.01, 0.015]
        
        var newSegments: [TrafficSegment] = []
        var requestCount = 0
        let maxRequests = 10 // Maximum number of requests to make at once
        
        for radius in radiusDistances {
            for i in 0..<numberOfDirections {
                // Check if we've hit the request limit
                if requestCount >= maxRequests {
                    continue
                }
                
                requestCount += 1
                
                let angle = Double(i) * (360.0 / Double(numberOfDirections))
                let destLat = location.coordinate.latitude + (radius * cos(angle.radians))
                let destLon = location.coordinate.longitude + (radius * sin(angle.radians))
                
                let destination = CLLocationCoordinate2D(latitude: destLat, longitude: destLon)
                
                do {
                    if let route = try await calculateRoute(from: location.coordinate, to: destination) {
                        for step in route.steps {
                            let coordinates = step.polyline.coordinates()
                            if coordinates.count >= 2 {
                                let segment = TrafficSegment(
                                    coordinates: coordinates,
                                    congestionLevel: generateRandomCongestion(),
                                    vehicleCount: Int.random(in: 1...3)
                                )
                                newSegments.append(segment)
                            }
                        }
                    }
                } catch {
                    if let error = error as? NSError,
                       error.domain == MKError.errorDomain,
                       error.code == MKError.Code.loadingThrottled.rawValue {
                        print("Traffic data rate limited, will retry later")
                        break
                    }
                }
            }
        }
        
        await MainActor.run {
            self.currentTrafficSegments = newSegments
            self.isGenerating = false
            self.lastUpdateTime = Date()
        }
    }
    
    private func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        activeDirectionsRequests.append(directions)
        
        do {
            let response = try await directions.calculate()
            activeDirectionsRequests.removeAll { $0 === directions }
            return response.routes.first
        } catch {
            activeDirectionsRequests.removeAll { $0 === directions }
            throw error
        }
    }
    
    func refresh() {
        generatePredictions()
        updateTrafficData()
    }
    
    deinit {
        timer?.invalidate()
        activeDirectionsRequests.forEach { $0.cancel() }
    }
}
