import SwiftUI
import MapKit

struct NavigationHeaderContent: View {
    @ObservedObject var routeManager: RouteManager
    @Binding var showStepsList: Bool
    
    var body: some View {
        VStack {
            if let step = routeManager.currentNavigationStep {
                NavigationHeaderView(
                    step: step,
                    destination: routeManager.destinationName ?? "Destination",
                    estimatedTime: routeManager.route?.expectedTravelTime,
                    totalDistance: routeManager.route?.distance,
                    showStepsList: $showStepsList
                )
                .padding(.horizontal)
                .padding(.top, 44)
            }
            
            Spacer()
            
            if let route = routeManager.route {
                NavigationInfoOverlay(
                    estimatedTime: route.expectedTravelTime,
                    remainingDistance: route.distance,
                    isNavigating: .constant(routeManager.isNavigating),
                    onExit: {
                        routeManager.endNavigation()
                    },
                    onAlternateRoutes: {}
                )
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

struct SearchContent: View {
    @Binding var searchText: String
    @Binding var showSearchResults: Bool
    let destinations: [MKMapItem]
    @Binding var selectedDestination: MKMapItem?
    @ObservedObject var routeManager: RouteManager
    let trafficManager: TrafficManager  // Changed to let instead of @ObservedObject
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, isActive: $showSearchResults) {
                // Search functionality is handled in onChange
            }
            .padding(.top, 44)
            
            if showSearchResults {
                SearchResultsView(destinations: destinations) { destination in
                    selectedDestination = destination
                    routeManager.setDestination(destination)
                    Task {
                        await trafficManager.generateTrafficForSearchedLocation(destination.placemark.coordinate)
                    }
                    showSearchResults = false
                    searchText = ""
                }
            }
            
            Spacer()
        }
    }
}

struct MapControlsContent: View {
    @ObservedObject var routeManager: RouteManager
    @Binding var mapType: MKMapType
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    if routeManager.isNavigating {
                        MapControlButton(icon: "mic", action: {})
                        MapControlButton(icon: "magnifyingglass", action: {})
                        MapControlButton(icon: "speaker.slash", action: {})
                        MapControlButton(icon: "location.north.fill", action: {
                            routeManager.recenterOnUser()
                        })
                        MapControlButton(icon: "map", action: {
                            mapType = mapType == .standard ? .hybrid : .standard
                        })
                        
                        CompassView(heading: routeManager.locationManager?.heading?.trueHeading)
                            .padding(.top, 8)
                    }
                }
                .padding(.trailing)
                .padding(.top, 44)
            }
            
            Spacer()
            
            if routeManager.isNavigating {
                HStack {
                    SpeedLimitView(speedLimit: 45)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
    }
}

struct RoutePreviewContent: View {
    let route: MKRoute
    let selectedDestination: MKMapItem
    @ObservedObject var routeManager: RouteManager
    @Binding var showStepsList: Bool
    
    var body: some View {
        VStack {
            Spacer()
            RoutePreviewView(
                route: route,
                source: MKMapItem(placemark: MKPlacemark(coordinate: routeManager.locationManager?.location?.coordinate ?? CLLocationCoordinate2D())),
                destinationItem: selectedDestination,
                destination: routeManager.destinationName ?? "Destination",
                onStartNavigation: {
                    routeManager.startNavigation()
                },
                showStepsList: $showStepsList
            )
        }
    }
}
