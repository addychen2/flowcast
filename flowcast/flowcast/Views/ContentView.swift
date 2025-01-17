import SwiftUI
import MapKit

extension View {
    func configureTabBar() -> some View {
        self.onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            tabBarAppearance.backgroundColor = .black
            
            // Configure unselected tab appearance
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .gray
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.gray
            ]
            
            // Configure selected tab appearance
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .white
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @StateObject private var routeManager: RouteManager
    @State private var selectedTab = 0
    @State private var mapType: MKMapType = .standard
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var destinations: [MKMapItem] = []
    @State private var showStepsList: Bool = false
    @State private var selectedDestination: MKMapItem?
    
    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _routeManager = StateObject(wrappedValue: RouteManager(locationManager: locationManager))
        locationManager.requestAuthorization()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Navigation View
            NavigationView {
                MapContainerView(
                    routeManager: routeManager,
                    mapType: $mapType,
                    searchText: $searchText,
                    showSearchResults: $showSearchResults,
                    destinations: $destinations,
                    showStepsList: $showStepsList,
                    selectedDestination: $selectedDestination
                )
            }
            .tabItem {
                Image(systemName: "map.fill")
                Text("Navigation")
            }
            .tag(0)
            
            // Traffic Prediction View
            TrafficPredictionView()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Traffic")
                }
                .tag(1)
        }
        .configureTabBar()
        .sheet(isPresented: $showStepsList) {
            if let route = routeManager.route {
                NavigationStepsListView(
                    route: route,
                    currentStepIndex: routeManager.stepIndex,
                    destination: routeManager.destinationName ?? "Destination",
                    isPresented: $showStepsList
                )
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                searchLocation()
            }
        }
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

struct MapContainerView: View {
    @ObservedObject var routeManager: RouteManager
    @Binding var mapType: MKMapType
    @Binding var searchText: String
    @Binding var showSearchResults: Bool
    @Binding var destinations: [MKMapItem]
    @Binding var showStepsList: Bool
    @Binding var selectedDestination: MKMapItem?
    
    var body: some View {
        ZStack(alignment: .top) {
            MapView(routeManager: routeManager, mapType: $mapType)
                .edgesIgnoringSafeArea(.all)
            
            if routeManager.isNavigating {
                NavigationHeaderContent(routeManager: routeManager, showStepsList: $showStepsList)
            } else {
                SearchContent(
                    searchText: $searchText,
                    showSearchResults: $showSearchResults,
                    destinations: destinations,
                    selectedDestination: $selectedDestination,
                    routeManager: routeManager
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
    }
}
