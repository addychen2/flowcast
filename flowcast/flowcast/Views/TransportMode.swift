import SwiftUI
import MapKit

enum TransportMode: CaseIterable {
    case car
    case transit
    case walk
    case bike
    case rideshare
    
    var icon: String {
        switch self {
        case .car: return "car.fill"
        case .transit: return "bus.fill"
        case .walk: return "figure.walk"
        case .bike: return "bicycle"
        case .rideshare: return "person.2.fill"
        }
    }
    
    var transportType: MKDirectionsTransportType {
        switch self {
        case .car: return .automobile
        case .transit: return .transit
        case .walk: return .walking
        case .bike: return .walking // Note: MKDirections doesn't have a bike type
        case .rideshare: return .automobile
        }
    }
}
