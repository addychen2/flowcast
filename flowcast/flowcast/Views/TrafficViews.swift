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

// Daily traffic row
struct DailyTrafficRow: View {
    let prediction: TrafficPrediction
    let date: Date
    @Binding var selectedPrediction: (TrafficPrediction, Date)?
    
    var body: some View {
        Button(action: {
            selectedPrediction = (prediction, date)
        }) {
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
        level.color
    }
}

struct Road {
    let coordinates: [CLLocationCoordinate2D]
    var congestionLevel: CongestionLevel = .low
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
        mapView.showsTraffic = false
        
        // Set region to show all of Hacienda Heights
        let center = CLLocationCoordinate2D(latitude: 34.032911, longitude: -117.972931)
        let span = MKCoordinateSpan(latitudeDelta: 0.024, longitudeDelta: 0.024)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: false)
        
        // Add road overlays
        addRoadOverlays(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        addRoadOverlays(to: mapView)
    }
    
    private func addRoadOverlays(to mapView: MKMapView) {
        for road in TrafficMapView.mainRoads {
            let polyline = MKPolyline(coordinates: road.coordinates, count: road.coordinates.count)
            mapView.addOverlay(polyline)
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
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemGreen
            renderer.lineWidth = 4
            renderer.alpha = 0.8
            return renderer
        }
    }
    
    // Define main roads as a static property
    static let mainRoads: [Road] = [
        // Valley Blvd (main diagonal road)
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.037741, longitude: -117.982931),
            CLLocationCoordinate2D(latitude: 34.032911, longitude: -117.972931),
            CLLocationCoordinate2D(latitude: 34.027911, longitude: -117.962931)
        ]),
        
        // Parallel road above Valley Blvd (Proctor)
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.039741, longitude: -117.982931),
            CLLocationCoordinate2D(latitude: 34.034911, longitude: -117.972931)
        ]),
        
        // Four Vertical Roads
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.042741, longitude: -117.976931),
            CLLocationCoordinate2D(latitude: 34.027741, longitude: -117.976931)
        ]),
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.042741, longitude: -117.972931),
            CLLocationCoordinate2D(latitude: 34.027741, longitude: -117.972931)
        ]),
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.042741, longitude: -117.968931),
            CLLocationCoordinate2D(latitude: 34.027741, longitude: -117.968931)
        ]),
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.042741, longitude: -117.964931),
            CLLocationCoordinate2D(latitude: 34.027741, longitude: -117.964931)
        ])
    ]
}

// Main traffic prediction view
struct TrafficPredictionView: View {
    @EnvironmentObject private var trafficManager: TrafficManager
    @State private var selectedPrediction: (TrafficPrediction, Date)?
    
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
                    // Location header
                    VStack(spacing: 4) {
                        Text("MY LOCATION")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        Text("Hacienda Heights")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("25%")
                            .font(.system(size: 96, weight: .thin))
                            .foregroundColor(.white)
                        
                        Text("Currently Light Traffic")
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
                    
                    // Traffic Map
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.gray)
                            Text("TRAFFIC")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .tracking(1.5)
                        }
                        .padding(.horizontal)
                        
                        TrafficMapView(trafficManager: trafficManager)
                            .frame(height: 320)
                            .cornerRadius(12)
                            .overlay(
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
                            )
                    }
                    .background(Color(.systemBackground).opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // 5-day forecast with updated dates
                    VStack(alignment: .leading, spacing: 16) {
                        Text("5-DAY TRAFFIC FORECAST")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        VStack(spacing: 16) {
                            ForEach(Array(zip(trafficManager.predictions.indices, trafficManager.predictions)), id: \.0) { index, prediction in
                                DailyTrafficRow(
                                    prediction: prediction,
                                    date: Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date(),
                                    selectedPrediction: $selectedPrediction
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
        }
        .sheet(item: Binding(
            get: { selectedPrediction.map { DetailedTrafficSelection(prediction: $0.0, date: $0.1) } },
            set: { if $0 == nil { selectedPrediction = nil } }
        )) { selection in
            DetailedTrafficView(date: selection.date, prediction: selection.prediction)
        }
    }
}

// Helper struct for sheet presentation
struct DetailedTrafficSelection: Identifiable {
    let id = UUID()
    let prediction: TrafficPrediction
    let date: Date
}

#Preview {
    TrafficPredictionView()
        .environmentObject(TrafficManager())
}
