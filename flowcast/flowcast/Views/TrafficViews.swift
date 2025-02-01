import SwiftUI
import MapKit

struct WeatherLocation: Identifiable {
    let id = UUID()
    let name: String
    let temperature: Int
    let condition: String
    let high: Int
    let low: Int
    let isCurrentLocation: Bool
}

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
        Image(systemName: getIcon())
            .foregroundColor(level.color)
    }
    
    private func getIcon() -> String {
        switch level {
        case .low: return "car"
        case .moderate: return "car.fill"
        case .heavy: return "exclamationmark.triangle.fill"
        }
    }
}

struct WeatherContentView: View {
    let location: WeatherLocation
    @EnvironmentObject private var trafficManager: TrafficManager
    @State private var selectedPrediction: (TrafficPrediction, Date)?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Location and temperature content
                if location.isCurrentLocation {
                    Text("MY LOCATION")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1.5)
                }
                
                Text(location.name)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(location.temperature)°")
                    .font(.system(size: 96, weight: .thin))
                    .foregroundColor(.white)
                
                Text(location.condition)
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                
                Text("H:\(location.high)° L:\(location.low)°")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                // Traffic section
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.gray)
                    Text("TRAFFIC")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1.5)
                }
                .padding(.top, 20)
                
                // Traffic map
                TrafficMapView(trafficManager: trafficManager)
                    .frame(height: 200)
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
                
                // Forecast section
                Text("5-DAY TRAFFIC FORECAST")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                    .padding(.top, 20)
                
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
            .padding(.horizontal)
            .padding(.top, 44)
            .padding(.bottom, 100)
        }
        .sheet(item: Binding(
            get: { selectedPrediction.map { DetailedTrafficSelection(prediction: $0.0, date: $0.1) } },
            set: { if $0 == nil { selectedPrediction = nil } }
        )) { selection in
            DetailedTrafficView(date: selection.date, prediction: selection.prediction)
        }
    }
}

struct TrafficMapView: UIViewRepresentable {
    let trafficManager: TrafficManager
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.overrideUserInterfaceStyle = .dark
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsBuildings = true
        mapView.showsTraffic = false
        
        let center = CLLocationCoordinate2D(latitude: 34.032911, longitude: -117.972931)
        let span = MKCoordinateSpan(latitudeDelta: 0.024, longitudeDelta: 0.024)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: false)
        
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
    
    static let mainRoads: [Road] = [
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.037741, longitude: -117.982931),
            CLLocationCoordinate2D(latitude: 34.032911, longitude: -117.972931),
            CLLocationCoordinate2D(latitude: 34.027911, longitude: -117.962931)
        ]),
        Road(coordinates: [
            CLLocationCoordinate2D(latitude: 34.039741, longitude: -117.982931),
            CLLocationCoordinate2D(latitude: 34.034911, longitude: -117.972931)
        ]),
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

struct TrafficPredictionView: View {
    @EnvironmentObject private var trafficManager: TrafficManager
    @State private var showWeatherList: Bool = false
    @State private var selectedLocation: Int = 0
    
    let locations = [
        WeatherLocation(name: "Merced", temperature: 48, condition: "Cloudy", high: 54, low: 38, isCurrentLocation: true),
        WeatherLocation(name: "Cupertino", temperature: 48, condition: "Cloudy", high: 56, low: 42, isCurrentLocation: false),
        WeatherLocation(name: "New York", temperature: 28, condition: "Mostly Cloudy", high: 31, low: 19, isCurrentLocation: false),
        WeatherLocation(name: "Alamo", temperature: 47, condition: "Light Rain", high: 53, low: 40, isCurrentLocation: false),
        WeatherLocation(name: "Midtown", temperature: 28, condition: "Mostly Cloudy", high: 31, low: 20, isCurrentLocation: false)
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.15)
                .ignoresSafeArea()
            
            StarsOverlay()
            
            // Main content
            VStack(spacing: 0) {
                TabView(selection: $selectedLocation) {
                    ForEach(locations.indices, id: \.self) { index in
                        WeatherContentView(location: locations[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Weather list button with pagination dots
            VStack {
                Spacer()
                WeatherListButton(
                    isListViewShowing: $showWeatherList,
                    currentPage: selectedLocation,
                    totalPages: locations.count
                )
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showWeatherList) {
            WeatherListView(
                locations: locations,
                selectedLocation: $selectedLocation,
                isPresented: $showWeatherList
            )
        }
    }
}

struct Road {
    let coordinates: [CLLocationCoordinate2D]
    var congestionLevel: CongestionLevel = .low
}

struct DetailedTrafficSelection: Identifiable {
    let id = UUID()
    let prediction: TrafficPrediction
    let date: Date
}

#Preview {
    TrafficPredictionView()
        .environmentObject(TrafficManager())
}
