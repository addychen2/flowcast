import SwiftUI

struct LoadingRouteView: View {
    @EnvironmentObject var routeManager: RouteManager
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if let error = routeManager.routeError {
                    // Error State
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if error.contains("Retrying") {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(.top)
                    }
                } else {
                    // Loading State
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Finding Routes")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Calculating the best routes for your trip...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Animated progress bars
                    VStack(spacing: 8) {
                        ForEach(0..<3) { _ in
                            LoadingBar()
                        }
                    }
                    .frame(width: 200)
                }
            }
        }
    }
}

struct LoadingBar: View {
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: isAnimating ? geometry.size.width * 0.7 : 0)
                )
        }
        .frame(height: 4)
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: Double.random(in: 1...2))
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LoadingRouteView()
        .environmentObject(RouteManager(locationManager: LocationManager()))
}
