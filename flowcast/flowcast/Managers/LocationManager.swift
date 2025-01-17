import Foundation
import CoreLocation
import SwiftUI
import Combine

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
    static let locationAuthorizationDidChange = Notification.Name("locationAuthorizationDidChange")
    static let headingDidUpdate = Notification.Name("headingDidUpdate")
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5  // Update every 5 meters
        locationManager.headingFilter = 5   // Update every 5 degrees
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestAuthorization() {
        print("Requesting location authorization...")
        locationManager.requestWhenInUseAuthorization()
        startUpdating()
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
            NotificationCenter.default.post(name: .locationAuthorizationDidChange, object: nil)
        case .denied, .restricted:
            stopUpdating()
            location = nil
            heading = nil
            error = LocationError.authorizationDenied
        case .notDetermined:
            stopUpdating()
            location = nil
            heading = nil
        @unknown default:
            stopUpdating()
            location = nil
            heading = nil
            error = LocationError.unknown
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Filter out invalid locations
        guard newLocation.horizontalAccuracy >= 0 else { return }
        
        // If we have a previous location, check if the new one is significantly different
        if let previousLocation = location {
            let distance = newLocation.distance(from: previousLocation)
            // Only update if moved more than 5 meters
            guard distance > 5 else { return }
        }
        
        location = newLocation
        NotificationCenter.default.post(name: .locationDidUpdate, object: newLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Filter out invalid headings
        guard newHeading.headingAccuracy >= 0 else { return }
        
        // If we have a previous heading, check if the new one is significantly different
        if let previousHeading = heading {
            let headingDifference = abs(newHeading.trueHeading - previousHeading.trueHeading)
            // Only update if heading changed by more than 5 degrees
            guard headingDifference > 5 else { return }
        }
        
        heading = newHeading
        NotificationCenter.default.post(name: .headingDidUpdate, object: newHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        self.error = error
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location access denied")
                stopUpdating()
                self.error = LocationError.authorizationDenied
            case .locationUnknown:
                print("Location unknown")
                self.error = LocationError.locationUnavailable
            default:
                print("Other Core Location error: \(clError.code)")
                self.error = LocationError.unknown
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        if let error = error {
            print("Deferred updates error: \(error.localizedDescription)")
            self.error = error
        }
    }
}

// MARK: - Custom Errors

enum LocationError: LocalizedError {
    case authorizationDenied
    case locationUnavailable
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location access was denied. Please enable location services in Settings."
        case .locationUnavailable:
            return "Unable to determine location. Please try again."
        case .unknown:
            return "An unknown location error occurred."
        }
    }
}

// MARK: - Helper Extensions

extension CLLocation {
    var speedInMPH: Double {
        return speed * 2.23694 // Convert m/s to mph
    }
    
    func bearingTo(_ location: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.radians
        let lon1 = self.coordinate.longitude.radians
        let lat2 = location.coordinate.latitude.radians
        let lon2 = location.coordinate.longitude.radians
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return (bearing.degrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension Double {
    var radians: Double {
        return self * .pi / 180
    }
    
    var degrees: Double {
        return self * 180 / .pi
    }
}
