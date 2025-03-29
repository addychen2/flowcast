import SwiftUI
import MapKit

struct MapContainerView: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var trafficManager: TrafficManager
    @Binding var mapType: MKMapType
    @Binding var searchText: String
    @Binding var showSearchResults: Bool
    @Binding var destinations: [MKMapItem]
    @Binding var showStepsList: Bool
    @Binding var selectedDestination: MKMapItem?
    @Binding var showSavedTrips: Bool
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map View (Full Screen)
            MapView(routeManager: routeManager,
                   trafficManager: trafficManager,
                   mapType: $mapType)
                .edgesIgnoringSafeArea(.all)
            
            // Top Content: Search Bar or Navigation Header
            VStack(spacing: 0) {
                if routeManager.isNavigating {
                    NavigationHeaderContent(
                        routeManager: routeManager,
                        showStepsList: $showStepsList
                    )
                } else {
                    // Search Bar Only - positioned higher with safe area awareness
                    SearchBar(text: $searchText, isActive: $showSearchResults) {
                        // Search functionality is handled in onChange
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
                    
                    // Search Results if active
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
                        .padding(.horizontal)
                    }
                }
            }
            
            // Map Controls (Right side)
            MapControlsContent(
                routeManager: routeManager,
                mapType: $mapType
            )
            
            // Route Preview (Bottom) when applicable
            if let route = routeManager.route,
               !routeManager.isNavigating,
               let selectedDestination = selectedDestination {
                RoutePreviewContent(
                    route: route,
                    selectedDestination: selectedDestination,
                    routeManager: routeManager,
                    showStepsList: $showStepsList
                )
            }
        }
        .sheet(isPresented: $routeManager.showRoutesSheet) {
            RoutesView(
                routes: routeManager.availableRoutes,
                onRouteSelect: { route in
                    routeManager.selectRoute(route)
                }
            )
        }
    }
}
