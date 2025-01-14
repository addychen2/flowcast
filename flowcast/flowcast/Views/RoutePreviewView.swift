import SwiftUI
import MapKit

struct RoutePreviewView: View {
    let route: MKRoute
    let onStartNavigation: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Route info
            HStack(spacing: 24) {
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.black.opacity(0.6))
                    Text("\(formatDuration(route.expectedTravelTime))")
                        .font(.system(size: 24, weight: .medium))
                }
                
                // Separator
                Rectangle()
                    .frame(width: 1, height: 24)
                    .foregroundColor(.gray.opacity(0.3))
                
                // Distance
                HStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .foregroundColor(.black.opacity(0.6))
                    Text(formatDistance(route.distance))
                        .font(.system(size: 24, weight: .medium))
                }
            }
            .padding(.vertical, 12)
            
            Divider()
            
            // Start button
            Button(action: onStartNavigation) {
                Text("Start")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        if hours > 0 {
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours) h \(remainingMinutes) min"
            }
            return "\(hours) h"
        }
        return "\(minutes) min"
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }
}
