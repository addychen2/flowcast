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

class TrafficManager: ObservableObject {
    @Published var predictions: [TrafficPrediction] = []
    @Published var currentTrafficSegments: [TrafficSegment] = []
    private var timer: Timer?
    weak var locationManager: LocationManager?
    private var isGenerating = false
    private var pendingLocation: CLLocation?
    private var activeDirectionsRequests: [MKDirections] = []
    
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
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateTrafficData()
        }
        updateTrafficData()
    }
    
    func updateTrafficData() {
        if let location = pendingLocation {
            generateTrafficAroundLocation(location)
            pendingLocation = nil
        } else if let location = locationManager?.location {
            generateTrafficAroundLocation(location)
        }
    }
    
    @MainActor
    func generateTrafficForSearchedLocation(_ coordinate: CLLocationCoordinate2D) {
        // Cancel any active directions requests
        activeDirectionsRequests.forEach { $0.cancel() }
        activeDirectionsRequests.removeAll()
        
        // Set the new location as pending
        pendingLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Immediately generate traffic for the new location
        updateTrafficData()
    }
    
    private func generateTrafficAroundLocation(_ location: CLLocation) {
        guard !isGenerating else { return }
        isGenerating = true
        
        let numberOfDirections = 12 // Increased number of directions for better coverage
        var newSegments: [TrafficSegment] = []
        let dispatchGroup = DispatchGroup()
        
        // Generate routes in multiple distances
        let radiusDistances = [0.005, 0.01, 0.015] // Multiple rings of routes
        
        for radius in radiusDistances {
            for i in 0..<numberOfDirections {
                dispatchGroup.enter()
                
                let angle = Double(i) * (360.0 / Double(numberOfDirections))
                let destLat = location.coordinate.latitude + (radius * cos(angle.radians))
                let destLon = location.coordinate.longitude + (radius * sin(angle.radians))
                
                let destination = CLLocationCoordinate2D(latitude: destLat, longitude: destLon)
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
                request.transportType = .automobile
                request.requestsAlternateRoutes = true
                
                let directions = MKDirections(request: request)
                activeDirectionsRequests.append(directions)
                
                directions.calculate { [weak self] response, error in
                    defer {
                        dispatchGroup.leave()
                        self?.activeDirectionsRequests.removeAll { $0 === directions }
                    }
                    
                    guard let routes = response?.routes else { return }
                    
                    // Take the first two alternate routes if available
                    let routesToUse = Array(routes.prefix(2))
                    
                    for route in routesToUse {
                        for step in route.steps {
                            let coordinates = step.polyline.coordinates()
                            if coordinates.count >= 2 {
                                let segment = TrafficSegment(
                                    coordinates: coordinates,
                                    congestionLevel: self?.generateRandomCongestion() ?? .low,
                                    vehicleCount: Int.random(in: 2...6)
                                )
                                newSegments.append(segment)
                            }
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.currentTrafficSegments = newSegments
            self?.isGenerating = false
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
