import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var trafficManager: TrafficManager
    @Binding var mapType: MKMapType
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var previousState: Bool = false
        var mapView: MKMapView?
        private var isInitialSetup = true
        private var currentTrafficOverlays: [TrafficOverlay] = []
        private var currentVehicleAnnotations: [VehicleAnnotation] = []
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let trafficOverlay = overlay as? TrafficOverlay {
                return mapView.updateTrafficRenderer(for: trafficOverlay)
            }
            
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 8
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let vehicleAnnotation = annotation as? VehicleAnnotation {
                return mapView.updateVehicleAnnotationView(for: vehicleAnnotation)
            }
            
            if annotation is MKUserLocation {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                
                // Size for your user location indicator
                let size = CGSize(width: 40, height: 40)
                let renderer = UIGraphicsImageRenderer(size: size)
                let locationImage = renderer.image { context in
                    let rect = CGRect(origin: .zero, size: size)
                    
                    // Outer white circle
                    UIColor.white.setFill()
                    UIBezierPath(ovalIn: rect).fill()
                    
                    // Inner blue circle
                    UIColor.systemBlue.setFill()
                    let innerRect = rect.insetBy(dx: 4, dy: 4)
                    UIBezierPath(ovalIn: innerRect).fill()
                    
                    // White accuracy ring
                    UIColor.white.setStroke()
                    let ringPath = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
                    ringPath.lineWidth = 2
                    ringPath.stroke()
                }
                
                annotationView.image = locationImage
                return annotationView
            }
            
            return nil
        }
        
        func updateTrafficVisualization(_ mapView: MKMapView) {
            // Remove existing traffic visualization
            mapView.removeOverlays(currentTrafficOverlays)
            mapView.removeAnnotations(currentVehicleAnnotations)
            currentTrafficOverlays.removeAll()
            currentVehicleAnnotations.removeAll()
            
            // Add new traffic overlays and vehicles
            for segment in parent.trafficManager.currentTrafficSegments {
                let overlay = TrafficOverlay.polyline(
                    coordinates: segment.coordinates,
                    count: segment.coordinates.count,
                    congestionLevel: segment.congestionLevel
                )
                currentTrafficOverlays.append(overlay)
                mapView.addOverlay(overlay)
                
                // Add vehicle annotations
                addVehicleAnnotations(mapView, for: segment)
            }
        }
        
        private func addVehicleAnnotations(_ mapView: MKMapView, for segment: TrafficSegment) {
            guard segment.coordinates.count >= 2 else { return }
            
            let start = segment.coordinates[0]
            let end = segment.coordinates[1]
            let direction = atan2(end.longitude - start.longitude,
                                end.latitude - start.latitude) * 180 / .pi
            
            for i in 0..<segment.vehicleCount {
                let progress = Double(i) / Double(segment.vehicleCount - 1)
                let latitude = start.latitude + (end.latitude - start.latitude) * progress
                let longitude = start.longitude + (end.longitude - start.longitude) * progress
                
                let vehicle = VehicleAnnotation(
                    coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                    direction: direction,
                    congestionLevel: segment.congestionLevel
                )
                currentVehicleAnnotations.append(vehicle)
                mapView.addAnnotation(vehicle)
            }
        }
        
        func setupNavigationMode(_ mapView: MKMapView) {
            self.mapView = mapView
            mapView.showsCompass = false
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(locationOrHeadingDidUpdate),
                name: .locationDidUpdate,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(locationOrHeadingDidUpdate),
                name: .headingDidUpdate,
                object: nil
            )
            
            if let location = parent.routeManager.locationManager?.location {
                updateCamera(with: location, heading: parent.routeManager.locationManager?.heading?.trueHeading ?? 0)
            }
        }
        
        @objc private func locationOrHeadingDidUpdate(_ notification: Notification) {
            guard let location = parent.routeManager.locationManager?.location,
                  let heading = parent.routeManager.locationManager?.heading?.trueHeading,
                  parent.routeManager.isNavigating else { return }
            
            updateCamera(with: location, heading: heading)
        }
        
        func recenterInNavigationMode() {
            guard let location = parent.routeManager.locationManager?.location,
                  let heading = parent.routeManager.locationManager?.heading?.trueHeading else { return }
            
            updateCamera(with: location, heading: heading)
        }
        
        private func updateCamera(with location: CLLocation, heading: CLLocationDirection) {
            guard let mapView = mapView else { return }
            
            let metersAhead: CLLocationDistance = 50
            let bearing = heading * .pi / 180
            
            let earthRadius: Double = 6371000
            let angularDistance = metersAhead / earthRadius
            
            let lat1 = location.coordinate.latitude * .pi / 180
            let lon1 = location.coordinate.longitude * .pi / 180
            
            let lat2 = asin(sin(lat1) * cos(angularDistance) +
                          cos(lat1) * sin(angularDistance) * cos(bearing))
            let lon2 = lon1 + atan2(sin(bearing) * sin(angularDistance) * cos(lat1),
                                  cos(angularDistance) - sin(lat1) * sin(lat2))
            
            let centerCoordinate = CLLocationCoordinate2D(
                latitude: lat2 * 180 / .pi,
                longitude: lon2 * 180 / .pi
            )
            
            let camera = MKMapCamera(
                lookingAtCenter: centerCoordinate,
                fromDistance: 300,
                pitch: 60,
                heading: heading
            )
            
            mapView.setCamera(camera, animated: true)
        }
        
        func setupPreviewMode(_ mapView: MKMapView) {
            NotificationCenter.default.removeObserver(self)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(
                center: mapView.userLocation.coordinate,
                span: span
            )
            mapView.setRegion(region, animated: true)
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if isInitialSetup {
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
                mapView.setRegion(region, animated: false)
                isInitialSetup = false
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsBuildings = true
        mapView.showsTraffic = false
        
        // Initial traffic visualization
        context.coordinator.updateTrafficVisualization(mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        
        // Update traffic visualization
        context.coordinator.updateTrafficVisualization(mapView)
        
        // Handle route overlays
        mapView.removeOverlays(mapView.overlays.filter { !($0 is TrafficOverlay) })
        if let route = routeManager.route {
            mapView.addOverlay(route.polyline)
        }
        
        if routeManager.shouldRecenter {
            context.coordinator.recenterInNavigationMode()
            routeManager.shouldRecenter = false
            return
        }
        
        if routeManager.isNavigating != context.coordinator.previousState {
            context.coordinator.previousState = routeManager.isNavigating
            
            if routeManager.isNavigating {
                context.coordinator.setupNavigationMode(mapView)
            } else {
                context.coordinator.setupPreviewMode(mapView)
            }
        }
    }
}
