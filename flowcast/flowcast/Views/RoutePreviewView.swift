import SwiftUI
import MapKit

struct RoutePreviewView: View {
    let route: MKRoute
    let source: MKMapItem
    let destinationItem: MKMapItem
    let destination: String
    let onStartNavigation: () -> Void
    @Binding var showStepsList: Bool
    @StateObject private var routeOptionsManager = RouteOptionsManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Route info card
            VStack(spacing: 16) {
                HStack {
                    Text(formatDuration(route.expectedTravelTime))
                        .font(.system(size: 24, weight: .semibold))
                    Text("(\(formatDistance(route.distance)))")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fastest route")
                            .font(.system(size: 16, weight: .medium))
                        if !route.advisoryNotices.isEmpty {
                            Text(route.advisoryNotices[0])
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                
                HStack(spacing: 24) {
                    Button(action: onStartNavigation) {
                        Text("Start")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(24)
                    }
                    
                    Button(action: { showStepsList = true }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Steps")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(24)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(remainingMinutes) min"
        }
        return "\(minutes) min"
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        if miles < 0.1 {
            let feet = Int(distance * 3.28084)
            return "\(feet) ft"
        }
        return String(format: "%.1f mi", miles)
    }
}
