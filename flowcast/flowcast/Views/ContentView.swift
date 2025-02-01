import SwiftUI
import MapKit
import FirebaseAuth

struct MapContainerView: View {
    @ObservedObject var routeManager: RouteManager
    @ObservedObject var trafficManager: TrafficManager
    @Binding var mapType: MKMapType
    @Binding var searchText: String
    @Binding var showSearchResults: Bool
    @Binding var destinations: [MKMapItem]
    @Binding var showStepsList: Bool
    @Binding var selectedDestination: MKMapItem?
    
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
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var mapType: MKMapType = .standard
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var destinations: [MKMapItem] = []
    @State private var showStepsList: Bool = false
    @State private var selectedDestination: MKMapItem?
    
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
            // Your existing main app view
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
                    selectedDestination: $selectedDestination
                )
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

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        if let email = authManager.user?.email {
                            Text(email)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section {
                    Button(role: .destructive) {
                        do {
                            try authManager.signOut()
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(RouteManager(locationManager: LocationManager()))
        .environmentObject(TrafficManager(locationManager: LocationManager()))
        .environmentObject(AuthenticationManager())
}
