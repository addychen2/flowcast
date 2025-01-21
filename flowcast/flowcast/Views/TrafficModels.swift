import MapKit

// Traffic data models
struct TrafficSegment {
    let coordinates: [CLLocationCoordinate2D]
    let congestionLevel: CongestionLevel
    let vehicleCount: Int
}

// Custom overlay for traffic visualization
class TrafficOverlay: MKPolyline {
    var congestionLevel: CongestionLevel = .low // Default value
    
    class func polyline(coordinates: [CLLocationCoordinate2D], count: Int, congestionLevel: CongestionLevel) -> TrafficOverlay {
        let polyline = TrafficOverlay(coordinates: UnsafePointer(coordinates), count: count)
        polyline.congestionLevel = congestionLevel
        return polyline
    }
}

// Custom annotation for vehicles
class VehicleAnnotation: MKPointAnnotation {
    var direction: Double
    var type: String
    var congestionLevel: CongestionLevel
    
    init(coordinate: CLLocationCoordinate2D, direction: Double, congestionLevel: CongestionLevel, type: String = "car") {
        self.direction = direction
        self.type = type
        self.congestionLevel = congestionLevel
        super.init()
        self.coordinate = coordinate
    }
}
