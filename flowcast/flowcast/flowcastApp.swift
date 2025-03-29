import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let db = Firestore.firestore()
        let settings = db.settings
        settings.isPersistenceEnabled = true // Enable offline persistence
        db.settings = settings
        
        // Register for remote notifications - required for Firebase Phone Auth
        registerForRemoteNotifications(application)
        
        return true
    }
    
    // Register for remote notifications
    private func registerForRemoteNotifications(_ application: UIApplication) {
        // Request authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("User granted permission for notifications")
            } else {
                print("User denied permission for notifications")
            }
            
            // Regardless of user's choice for notifications, register for remote notifications
            // This is needed for silent notifications used by Firebase Auth
            DispatchQueue.main.async {
                print("Registering for remote notifications")
                application.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - Handle Remote Notifications for Firebase

    // This method is called when a remote notification is received
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Forward the notification to Firebase Auth
        if Auth.auth().canHandleNotification(userInfo) {
            print("Forwarding remote notification to Firebase Auth")
            completionHandler(.noData)
            return
        }
        
        // Handle other remote notifications if needed
        print("Remote notification not handled by Firebase Auth")
        completionHandler(.noData)
    }
    
    // Register for remote notifications
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward device token to Firebase Auth
        print("Registering device token with Firebase Auth")
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }
    
    // MARK: - Handle URL schemes
    
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Try to handle the URL by Firebase Auth first
        if Auth.auth().canHandle(url) {
            print("URL handled by Firebase Auth")
            return true
        }
        
        // Handle other URL schemes if needed
        print("URL not handled by Firebase Auth")
        return false
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
