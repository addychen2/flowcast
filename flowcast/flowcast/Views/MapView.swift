import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var routeManager: RouteManager
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var previousState: Bool = false
        var navigationCamera: MKMapCamera?
        var mapView: MKMapView?
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                annotationView.image = UIImage(systemName: "location.north.fill")?
                    .withTintColor(.blue, renderingMode: .alwaysOriginal)
                return annotationView
            }
            return nil
        }
        
        // Add delegate method for when user tracking mode changes
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            print("Tracking mode changed to: \(mode.rawValue)")
            // If we're in navigation mode but not in followWithHeading, reset it
            if parent.routeManager.isNavigating && mode != .followWithHeading {
                mapView.setUserTrackingMode(.followWithHeading, animated: true)
            }
        }
        
        func setupNavigationMode(_ mapView: MKMapView) {
            print("Entering navigation mode")
            self.mapView = mapView
            mapView.setUserTrackingMode(.followWithHeading, animated: false)
            
            // Set close zoom
            let region = MKCoordinateRegion(
                center: mapView.userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            mapView.setRegion(region, animated: false)
            
            // Lock the zoom
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: region)
            mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 250,
                                                              maxCenterCoordinateDistance: 250)
        }
        
        func setupPreviewMode(_ mapView: MKMapView) {
            print("Exiting navigation mode")
            // Remove navigation constraints
            mapView.cameraBoundary = nil
            mapView.cameraZoomRange = nil
            navigationCamera = nil
            
            mapView.setUserTrackingMode(.follow, animated: false)
            
            let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let userRegion = MKCoordinateRegion(
                center: mapView.userLocation.coordinate,
                span: defaultSpan
            )
            mapView.setRegion(userRegion, animated: true)
        }
        
        func recenterInNavigationMode() {
            guard let mapView = mapView else { return }
            
            // Force re-enable follow with heading mode
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
            
            // Set close zoom
            let region = MKCoordinateRegion(
                center: mapView.userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            mapView.setRegion(region, animated: true)
            
            // Reset the zoom constraints
            mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: region)
            mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 250,
                                                              maxCenterCoordinateDistance: 250)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Customize map appearance
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = true
        mapView.showsTraffic = true
        mapView.isRotateEnabled = true
        
        // Set initial view with default zoom
        if let userLocation = routeManager.locationManager?.location?.coordinate {
            let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(
                center: userLocation,
                span: defaultSpan
            )
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Handle route overlay updates
        mapView.removeOverlays(mapView.overlays)
        if let route = routeManager.route {
            mapView.addOverlay(route.polyline)
        }
        
        // Handle recenter request
        if routeManager.shouldRecenter {
            context.coordinator.recenterInNavigationMode()
            routeManager.shouldRecenter = false
            return
        }
        
        // Only handle changes in navigation state
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
