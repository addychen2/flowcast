import SwiftUI
import MapKit

struct RoutesView: View {
    let routes: [MKRoute]
    let onRouteSelect: (MKRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(routes.enumerated()), id: \.offset) { index, route in
                    RouteOptionRow(route: route, isRecommended: index == 0) {
                        onRouteSelect(route)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Available Routes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RouteOptionRow: View {
    let route: MKRoute
    let isRecommended: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Route header with time and distance
                HStack {
                    HStack(spacing: 4) {
                        Text(formatDuration(route.expectedTravelTime))
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("(\(formatDistance(route.distance)))")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if isRecommended {
                        Text("Recommended")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                
                // Route details
                VStack(alignment: .leading, spacing: 8) {
                    // Major roads used
                    HStack {
                        Image(systemName: "road.lanes")
                            .foregroundColor(.blue)
                        Text(getMainRoads(from: route))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    // Traffic condition
                    HStack {
                        Image(systemName: getTrafficIcon(for: route))
                            .foregroundColor(getTrafficColor(for: route))
                        Text(getTrafficDescription(for: route))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // ETA
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("ETA: \(calculateETA(route.expectedTravelTime))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes) min"
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        return String(format: "%.1f mi", miles)
    }
    
    private func getMainRoads(from route: MKRoute) -> String {
        // Extract major road names from route steps
        let majorRoads = route.steps
            .compactMap { step -> String? in
                let name = step.instructions
                    .components(separatedBy: " onto ")
                    .last?
                    .components(separatedBy: " at ").first
                return name?.contains("I-") ?? false ? name : nil
            }
            .unique()
            .joined(separator: " → ")
        
        return majorRoads.isEmpty ? "Local roads" : majorRoads
    }
    
    private func getTrafficIcon(for route: MKRoute) -> String {
        let averageSpeed = route.expectedTravelTime / (route.distance / 1609.34)
        switch averageSpeed {
        case ...45: return "exclamationmark.triangle.fill"
        case 46...60: return "car.fill"
        default: return "car"
        }
    }
    
    private func getTrafficColor(for route: MKRoute) -> Color {
        let averageSpeed = route.expectedTravelTime / (route.distance / 1609.34)
        switch averageSpeed {
        case ...45: return .red
        case 46...60: return .orange
        default: return .green
        }
    }
    
    private func getTrafficDescription(for route: MKRoute) -> String {
        let averageSpeed = route.expectedTravelTime / (route.distance / 1609.34)
        switch averageSpeed {
        case ...45: return "Heavy traffic"
        case 46...60: return "Moderate traffic"
        default: return "Light traffic"
        }
    }
    
    private func calculateETA(_ duration: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let arrivalTime = Date().addingTimeInterval(duration)
        return formatter.string(from: arrivalTime)
    }
}

extension Sequence where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
