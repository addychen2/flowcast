import SwiftUI
import MapKit

// Stars background effect
struct StarsOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<100) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: 1, height: 1)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(Double.random(in: 0.1...0.5))
            }
        }
    }
}

// Hourly traffic scroll view
struct HourlyTrafficScrollView: View {
    let hours: [(String, Double)]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(hours, id: \.0) { hour, congestion in
                VStack(spacing: 8) {
                    Text(hour)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Image(systemName: getTrafficIcon(for: congestion))
                        .font(.system(size: 24))
                        .foregroundColor(getTrafficColor(for: congestion))
                    
                    Text("\(Int(congestion))%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 60)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func getTrafficIcon(for congestion: Double) -> String {
        if congestion < 40 { return "car" }
        if congestion < 70 { return "car.fill" }
        return "exclamationmark.triangle.fill"
    }
    
    private func getTrafficColor(for congestion: Double) -> Color {
        if congestion < 40 { return .green }
        if congestion < 70 { return .orange }
        return .red
    }
}

// Daily traffic row
struct DailyTrafficRow: View {
    let prediction: TrafficPrediction
    
    var body: some View {
        HStack {
            Text(prediction.dayName)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 12) {
                TrafficIndicator(level: prediction.morning)
                TrafficIndicator(level: prediction.afternoon)
                TrafficIndicator(level: prediction.evening)
            }
        }
    }
}

// Traffic indicator
struct TrafficIndicator: View {
    let level: CongestionLevel
    
    var body: some View {
        HStack {
            Image(systemName: getIcon())
                .foregroundColor(getColor())
        }
        .frame(width: 40)
    }
    
    private func getIcon() -> String {
        switch level {
        case .low: return "car"
        case .moderate: return "car.fill"
        case .heavy: return "exclamationmark.triangle.fill"
        }
    }
    
    private func getColor() -> Color {
        switch level {
        case .low: return .green
        case .moderate: return .orange
        case .heavy: return .red
        }
    }
}

// Main traffic prediction view
struct TrafficPredictionView: View {
    @StateObject private var trafficManager = TrafficManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0292, longitude: -117.9686),
        span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
    )
    
    var body: some View {
        ZStack {
            // Night sky background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Star effect overlay
            StarsOverlay()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Main location and temperature-style display
                    VStack(spacing: 4) {
                        Text("MY LOCATION")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        Text("Hacienda Heights")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Current congestion level display
                        Text("\(getCurrentCongestionLevel())")
                            .font(.system(size: 96, weight: .thin))
                            .foregroundColor(.white)
                        
                        Text("Currently \(getCurrentDescription())")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .padding(.top, -10)
                            
                        HStack {
                            Text("Peak: Heavy")
                            Text("Low: Light")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 44)
                    
                    // Traffic Map Widget
                    TrafficMapWidget(trafficManager: trafficManager)
                        .frame(height: 320)
                    
                    // Hourly traffic forecast
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HOURLY TRAFFIC")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HourlyTrafficScrollView(hours: generateHourlyTraffic())
                        }
                    }
                    .padding(.top, 20)
                    
                    // 5-day forecast
                    VStack(alignment: .leading, spacing: 16) {
                        Text("5-DAY TRAFFIC FORECAST")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        VStack(spacing: 16) {
                            ForEach(trafficManager.predictions, id: \.dayName) { prediction in
                                DailyTrafficRow(prediction: prediction)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func getCurrentCongestionLevel() -> String {
        "70%"  // Example value
    }
    
    private func getCurrentDescription() -> String {
        "Moderate Traffic"
    }
    
    private func generateHourlyTraffic() -> [(String, Double)] {
        let hours = ["Now", "11PM", "12AM", "1AM", "2AM", "3AM"]
        return hours.map { ($0, Double.random(in: 30...90)) }
    }
}

struct TrafficMapWidget: View {
    let trafficManager: TrafficManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.gray)
                Text("TRAFFIC")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(1.5)
            }
            .padding(.horizontal)
            
            // Map container
            ZStack {
                // Base map with dark mode styling
                TrafficMapView(trafficManager: trafficManager)
                    .cornerRadius(12)
                
                // Traffic overlay legend
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        ForEach(CongestionLevel.allCases, id: \.self) { level in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(level.color.opacity(0.6))
                                    .frame(width: 8, height: 8)
                                Text(level.rawValue)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemBackground).opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct TrafficMapView: UIViewRepresentable {
    let trafficManager: TrafficManager

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Configure map appearance
        mapView.overrideUserInterfaceStyle = .dark
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsBuildings = true
        mapView.showsTraffic = true  // Show Apple's built-in traffic while we develop our visualization
        
        // Set the region to show Hacienda Heights area - more zoomed in
        let centerCoordinate = CLLocationCoordinate2D(latitude: 34.0292, longitude: -117.9686) // Hacienda Heights
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Much more zoomed in
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: false)
        
        // Enable user interaction
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Example road segments around Hacienda Heights
        let roads = [
            // Hacienda Blvd
            [
                CLLocationCoordinate2D(latitude: 34.0292, longitude: -117.9686),
                CLLocationCoordinate2D(latitude: 34.0350, longitude: -117.9686)
            ],
            // Colima Rd
            [
                CLLocationCoordinate2D(latitude: 34.0292, longitude: -117.9600),
                CLLocationCoordinate2D(latitude: 34.0292, longitude: -117.9750)
            ],
            // Gale Ave
            [
                CLLocationCoordinate2D(latitude: 34.0250, longitude: -117.9686),
                CLLocationCoordinate2D(latitude: 34.0250, longitude: -117.9750)
            ]
        ]
        
        // Add traffic overlays for each road
        for road in roads {
            let congestion = CongestionLevel.allCases.randomElement() ?? .moderate
            let overlay = TrafficOverlay.polyline(
                coordinates: road,
                count: road.count,
                congestionLevel: congestion
            )
            mapView.addOverlay(overlay)
        }
        
        // Also add any segments from trafficManager
        for segment in trafficManager.currentTrafficSegments {
            let overlay = TrafficOverlay.polyline(
                coordinates: segment.coordinates,
                count: segment.coordinates.count,
                congestionLevel: segment.congestionLevel
            )
            mapView.addOverlay(overlay)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TrafficMapView
        
        init(_ parent: TrafficMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let trafficOverlay = overlay as? TrafficOverlay {
                let renderer = MKPolylineRenderer(overlay: trafficOverlay)
                
                switch trafficOverlay.congestionLevel {
                case .low:
                    renderer.strokeColor = .systemGreen
                case .moderate:
                    renderer.strokeColor = .systemOrange
                case .heavy:
                    renderer.strokeColor = .systemRed
                }
                
                renderer.lineWidth = 4
                renderer.alpha = 0.7
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
