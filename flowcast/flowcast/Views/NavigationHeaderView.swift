import SwiftUI
import MapKit

struct NavigationHeaderView: View {
    let step: MKRoute.Step
    let destination: String
    let estimatedTime: TimeInterval?
    let totalDistance: CLLocationDistance?
    @Binding var showStepsList: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Main navigation header
            VStack(alignment: .leading, spacing: 4) {
                // Distance and turn instruction
                HStack(alignment: .center) {
                    Image(systemName: getDirectionIcon(for: step))
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Text("\(formatDistance(step.distance))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(step.instructions)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Button(action: { showStepsList.toggle() }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // ETA and total distance info
                if let estimatedTime = estimatedTime {
                    HStack {
                        Text("\(formatDuration(estimatedTime)) (\(formatDistance(totalDistance ?? 0)))")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(red: 0.106, green: 0.482, blue: 0.267))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func getDirectionIcon(for step: MKRoute.Step) -> String {
        let instructions = step.instructions.lowercased()
        if instructions.contains("right") {
            return "arrow.turn.up.right"
        } else if instructions.contains("left") {
            return "arrow.turn.up.left"
        } else if instructions.contains("merge") {
            return "arrow.merge"
        } else if instructions.contains("exit") {
            return "arrow.up.right"
        } else if instructions.contains("u-turn") {
            return "arrow.uturn.right"
        } else {
            return "arrow.up"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1609.34 { // More than 1 mile
            let miles = distance / 1609.34
            return String(format: "%.1f mi", miles)
        } else {
            let feet = Int(distance * 3.28084)
            return "\(feet) ft"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}
