import SwiftUI
import MapKit
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var mapType: MKMapType = .standard
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var destinations: [MKMapItem] = []
    @State private var showStepsList: Bool = false
    @State private var selectedDestination: MKMapItem?
    @State private var showSavedTrips = false
    
    // Access the environment objects
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var routeManager: RouteManager
    @EnvironmentObject var trafficManager: TrafficManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                AuthenticationView()
            } else {
                authenticatedContent
            }
        }
    }
    
    private var authenticatedContent: some View {
        TabView(selection: $selectedTab) {
            // Home View
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Navigation View
            NavigationView {
                MapContainerView(
                    routeManager: routeManager,
                    trafficManager: trafficManager,
                    mapType: $mapType,
                    searchText: $searchText,
                    showSearchResults: $showSearchResults,
                    destinations: $destinations,
                    showStepsList: $showStepsList,
                    selectedDestination: $selectedDestination,
                    showSavedTrips: $showSavedTrips
                )
                .withSafeAreaInsets() // Add safe area insets to environment
                // Removed toolbar items with bookmark button
            }
            .sheet(isPresented: $showSavedTrips) {
                SavedTripsView()
                    .environmentObject(routeManager)
                    .environmentObject(authManager)
            }
            .tabItem {
                Label("Navigation", systemImage: "map.fill")
            }
            .tag(1)
            
            // Traffic View
            TrafficPredictionView()
                .environmentObject(trafficManager)
                .tabItem {
                    Label("Traffic", systemImage: "car.fill")
                }
                .tag(2)
            
            // Profile View with Sign Out
            ProfileView()
                .environmentObject(authManager)
                .environmentObject(routeManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .onAppear {
            // Configure TabBar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
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

struct HomeView: View {
    var body: some View {
        Text("Home View")
    }
}
