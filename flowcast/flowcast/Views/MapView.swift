import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var routeManager: RouteManager
    @Binding var mapType: MKMapType
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var previousState: Bool = false
        var mapView: MKMapView?
        private var isInitialSetup = true
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 8
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                
                let size = CGSize(width: 40, height: 40)
                let renderer = UIGraphicsImageRenderer(size: size)
                let arrowImage = renderer.image { context in
                    let rect = CGRect(origin: .zero, size: size)
                    
                    UIColor.white.setFill()
                    let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
                    circlePath.fill()
                    
                    UIColor.systemBlue.setFill()
                    let arrowPath = UIBezierPath()
                    arrowPath.move(to: CGPoint(x: size.width/2, y: 5))
                    arrowPath.addLine(to: CGPoint(x: size.width - 10, y: size.height - 10))
                    arrowPath.addLine(to: CGPoint(x: size.width/2, y: size.height - 15))
                    arrowPath.addLine(to: CGPoint(x: 10, y: size.height - 10))
                    arrowPath.close()
                    arrowPath.fill()
                }
                
                annotationView.image = arrowImage
                return annotationView
            }
            return nil
        }
        
        func setupNavigationMode(_ mapView: MKMapView) {
            self.mapView = mapView
            mapView.showsCompass = false
            
            // Instead of using userTrackingMode, we'll observe location and heading changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(locationOrHeadingDidUpdate),
                name: .locationDidUpdate,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(locationOrHeadingDidUpdate),
                name: .headingDidUpdate, // You'll need to add this notification
                object: nil
            )
            
            // Initial camera setup
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
        
        private func updateCamera(with location: CLLocation, heading: CLLocationDirection) {
            guard let mapView = mapView else { return }
            
            // Calculate a point ahead of the user's location
            let metersAhead: CLLocationDistance = 50  // Distance to look ahead
            let bearing = heading * .pi / 180  // Convert to radians
            
            // Calculate the coordinate to center on
            let earthRadius: Double = 6371000  // Earth's radius in meters
            let angularDistance = metersAhead / earthRadius
            
            let lat1 = location.coordinate.latitude * .pi / 180
            let lon1 = location.coordinate.longitude * .pi / 180
            
            let lat2 = asin(sin(lat1) * cos(angularDistance) +
                          cos(lat1) * sin(angularDistance) * cos(bearing))
            let lon2 = lon1 + atan2(sin(bearing) * sin(angularDistance) * cos(lat1),
                                  cos(angularDistance) - sin(lat1) * sin(lat2))
            
            // Convert back to degrees
            let centerCoordinate = CLLocationCoordinate2D(
                latitude: lat2 * 180 / .pi,
                longitude: lon2 * 180 / .pi
            )
            
            // Create camera with offset center point
            let camera = MKMapCamera(
                lookingAtCenter: centerCoordinate,
                fromDistance: 300,  // Zoomed in view
                pitch: 60,
                heading: heading
            )
            
            mapView.setCamera(camera, animated: true)
        }
        
        func recenterInNavigationMode() {
            guard let location = parent.routeManager.locationManager?.location,
                  let heading = parent.routeManager.locationManager?.heading?.trueHeading else { return }
            
            updateCamera(with: location, heading: heading)
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
        mapView.showsTraffic = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        
        mapView.removeOverlays(mapView.overlays)
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
