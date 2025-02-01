import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct flowcastApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize managers at app level
    @StateObject private var locationManager = LocationManager()
    @StateObject private var routeManager: RouteManager
    @StateObject private var trafficManager: TrafficManager
    @StateObject private var authManager = AuthenticationManager()
    
    init() {
        let locationManager = LocationManager()
        _routeManager = StateObject(wrappedValue: RouteManager(locationManager: locationManager))
        _trafficManager = StateObject(wrappedValue: TrafficManager(locationManager: locationManager))
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(locationManager)
                    .environmentObject(routeManager)
                    .environmentObject(trafficManager)
                    .environmentObject(authManager)
            }
        }
    }
}
