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
                
                // Custom arrow image for user location
                let size = CGSize(width: 40, height: 40)
                let renderer = UIGraphicsImageRenderer(size: size)
                let arrowImage = renderer.image { context in
                    let rect = CGRect(origin: .zero, size: size)
                    
                    // Draw white circle background
                    UIColor.white.setFill()
                    let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
                    circlePath.fill()
                    
                    // Draw blue arrow
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
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
        }
        
        func recenterInNavigationMode() {
            guard let mapView = mapView else { return }
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
        }
        
        func setupPreviewMode(_ mapView: MKMapView) {
            mapView.setUserTrackingMode(.none, animated: true)
            
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        
        // Map appearance
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update map type
        mapView.mapType = mapType
        
        // Route overlay
        mapView.removeOverlays(mapView.overlays)
        if let route = routeManager.route {
            mapView.addOverlay(route.polyline)
        }
        
        // Handle recenter
        if routeManager.shouldRecenter {
            context.coordinator.recenterInNavigationMode()
            routeManager.shouldRecenter = false
            return
        }
        
        // Navigation state changes
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
