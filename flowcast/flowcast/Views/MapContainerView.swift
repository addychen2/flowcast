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
    
    var body: some View {
        ZStack(alignment: .top) {
            MapView(routeManager: routeManager,
                   trafficManager: trafficManager,
                   mapType: $mapType)
                .edgesIgnoringSafeArea(.all)
            
            if routeManager.isNavigating {
                NavigationHeaderContent(
                    routeManager: routeManager,
                    showStepsList: $showStepsList
                )
            } else {
                SearchContent(
                    searchText: $searchText,
                    showSearchResults: $showSearchResults,
                    destinations: destinations,
                    selectedDestination: $selectedDestination,
                    routeManager: routeManager,
                    trafficManager: trafficManager
                )
            }
            
            MapControlsContent(
                routeManager: routeManager,
                mapType: $mapType
            )
            
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showSavedTrips = true
                }) {
                    Image(systemName: "bookmark.fill")
                        .foregroundColor(.blue)
                }
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
