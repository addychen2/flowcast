import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @StateObject private var routeManager: RouteManager
    
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var destinations: [MKMapItem] = []
    
    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _routeManager = StateObject(wrappedValue: RouteManager(locationManager: locationManager))
        
        // Request authorization and start updating location
        locationManager.requestAuthorization()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            MapView(routeManager: routeManager)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Dismiss keyboard
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                 to: nil, from: nil, for: nil)
                    showSearchResults = false
                }
            
            VStack(spacing: 0) {
                Group {
                    if routeManager.isNavigating, let step = routeManager.currentNavigationStep {
                        NavigationHeaderView(
                            step: step,
                            destination: routeManager.destinationName ?? "Destination",
                            estimatedTime: routeManager.route?.expectedTravelTime,
                            totalDistance: routeManager.route?.distance
                        )
                    } else {
                        SearchBar(text: $searchText, isActive: $showSearchResults) {
                            searchLocation()
                        }
                        .padding()
                    }
                }
                
                if showSearchResults {
                    SearchResultsView(destinations: destinations) { destination in
                        routeManager.setDestination(destination)
                        showSearchResults = false
                        searchText = ""
                    }
                }
                
                Spacer()
                
                if let route = routeManager.route, !routeManager.isNavigating {
                    RoutePreviewView(route: route) {
                        routeManager.startNavigation()
                    }
                }
            }
            
            if routeManager.isNavigating {
                VStack {
                    HStack {
                        Button(action: {
                            routeManager.endNavigation()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding()
                        
                        Spacer()
                    }
                    Spacer()
                    
                    // Recenter button
                    HStack {
                        Spacer()
                        Button(action: {
                            routeManager.recenterOnUser()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
        }
        .alert("Location Access Required",
               isPresented: .constant(locationManager.authorizationStatus == .denied),
               actions: {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        }, message: {
            Text("Please enable location access in Settings to use navigation features.")
        })
    }
    
    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = routeManager.region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            destinations = response.mapItems
            showSearchResults = true
        }
    }
}
