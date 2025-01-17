import SwiftUI
import MapKit

class RouteOptionsManager: ObservableObject {
    @Published var routeOptions: [RouteOption] = TransportMode.allCases.map {
        RouteOption(mode: $0, route: nil, isCalculating: false, error: nil)
    }
    @Published var selectedMode: TransportMode = .car
    
    func calculateRoutes(from source: MKMapItem, to destination: MKMapItem) {
        for index in routeOptions.indices {
            calculateRoute(for: index, from: source, to: destination)
        }
    }
    
    private func calculateRoute(for index: Int, from source: MKMapItem, to destination: MKMapItem) {
        let mode = routeOptions[index].mode
        
        // Skip bike and rideshare for now as they require special handling
        guard mode != .bike && mode != .rideshare else {
            DispatchQueue.main.async {
                self.routeOptions[index].error = NSError(domain: "com.app.routing",
                                                       code: -1,
                                                       userInfo: [NSLocalizedDescriptionKey: "Mode not supported"])
                self.routeOptions[index].isCalculating = false
            }
            return
        }
        
        routeOptions[index].isCalculating = true
        routeOptions[index].error = nil
        
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = mode.transportType
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.routeOptions[index].error = error
                } else if let route = response?.routes.first {
                    self.routeOptions[index].route = route
                }
                self.routeOptions[index].isCalculating = false
            }
        }
    }
    
    func clearRoutes() {
        routeOptions = TransportMode.allCases.map {
            RouteOption(mode: $0, route: nil, isCalculating: false, error: nil)
        }
        selectedMode = .car
    }
}
