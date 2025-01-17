import Foundation
import MapKit

struct RouteOption: Identifiable {
    let id = UUID()
    let mode: TransportMode
    var route: MKRoute?
    var isCalculating: Bool
    var error: Error?
}
