import SwiftUI
import MapKit

struct MapControlsView: View {
    @Binding var isNavigating: Bool
    @Binding var mapType: MKMapType
    let onRecenter: () -> Void
    
    var body: some View {
        VStack {
            // Right side controls
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    if isNavigating {
                        MapControlButton(icon: "mic", action: {})
                        MapControlButton(icon: "magnifyingglass", action: {})
                        MapControlButton(icon: "speaker.slash", action: {})
                        MapControlButton(icon: "location.north.fill", action: onRecenter)
                        MapControlButton(icon: "map", action: {
                            mapType = mapType == .standard ? .hybrid : .standard
                        })
                    }
                }
                .padding(.trailing)
                .padding(.top, 44)
            }
            
            Spacer()
            
            // Bottom controls (when navigating)
            if isNavigating {
                HStack {
                    // Speed limit
                    SpeedLimitView(speedLimit: 45)
                        .padding(.leading)
                    
                    Spacer()
                    
                    // Alternative routes button
                    Button(action: {}) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 8)
                    
                    // Exit button
                    Button(action: { isNavigating = false }) {
                        Text("Exit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(24)
                            .shadow(radius: 2)
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 32)
            }
        }
    }
}
