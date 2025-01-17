import SwiftUI
import MapKit

struct NavigationInfoOverlay: View {
    let estimatedTime: TimeInterval?
    let remainingDistance: CLLocationDistance?
    @Binding var isNavigating: Bool
    let onExit: () -> Void
    let onAlternateRoutes: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Pull up handle
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 4)
                .cornerRadius(2)
                .padding(.vertical, 8)
            
            // Main content
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(formatDuration(estimatedTime ?? 0))
                            .font(.system(size: 18, weight: .semibold))
                        Text("·")
                        Text(formatDistance(remainingDistance ?? 0))
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Text(formatArrivalTime())
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onAlternateRoutes) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.black)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                    
                    Button(action: onExit) {
                        Text("Exit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                    .frame(height: 40)
                    .background(Color.red)
                    .cornerRadius(20)
                    .shadow(radius: 2)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        return String(format: "%.1f mi", miles)
    }
    
    private func formatArrivalTime() -> String {
        let calendar = Calendar.current
        if let duration = estimatedTime {
            let arrivalDate = Date().addingTimeInterval(duration)
            return "Arrive by \(formatTime(arrivalDate))"
        }
        return ""
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Helper for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                               byRoundingCorners: corners,
                               cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
