import SwiftUI
import MapKit

struct NavigationHeaderView: View {
    let step: MKRoute.Step
    let destination: String
    let estimatedTime: TimeInterval?
    let totalDistance: CLLocationDistance?
    
    var body: some View {
        VStack(spacing: 0) {
            // Main direction header
            HStack(alignment: .center, spacing: 12) {
                // Direction icon
                Image(systemName: getDirectionIcon(for: step))
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Distance to next turn
                    Text(formatDistance(step.distance))
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    // Destination or street name
                    Text(destination)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Microphone button (placeholder)
                Button(action: {}) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.green)
            
            // Time and distance info
            if let estimatedTime = estimatedTime, let totalDistance = totalDistance {
                HStack {
                    Text("\(formatDuration(estimatedTime)) (\(formatDistance(totalDistance)))")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.white)
                .shadow(radius: 2)
            }
        }
    }
    
    private func getDirectionIcon(for step: MKRoute.Step) -> String {
        // Basic turn detection from instructions
        let instructions = step.instructions.lowercased()
        if instructions.contains("right") {
            return "arrow.turn.up.right"
        } else if instructions.contains("left") {
            return "arrow.turn.up.left"
        } else if instructions.contains("continue") || instructions.contains("head") {
            return "arrow.up"
        } else {
            return "arrow.up" // Default
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}
