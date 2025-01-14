import Foundation
import CoreLocation
import SwiftUI
import Combine

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5  // Update every 5 meters
        locationManager.headingFilter = 5
    }
    
    func requestAuthorization() {
        print("Requesting location authorization...")
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            NotificationCenter.default.post(name: .locationAuthorizationDidChange, object: nil)
        default:
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
            location = nil
            heading = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        if let location = location {
            print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            NotificationCenter.default.post(name: .locationDidUpdate, object: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
        print("Heading updated: \(newHeading.trueHeading) degrees")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied")
            case .locationUnknown:
                print("Location unknown")
            default:
                print("Other Core Location error: \(clError.code)")
            }
        }
    }
}
