import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let db = Firestore.firestore()
        let settings = db.settings
        settings.isPersistenceEnabled = true // Enable offline persistence
        db.settings = settings
        
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
