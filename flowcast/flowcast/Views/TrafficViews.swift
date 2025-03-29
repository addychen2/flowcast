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
    @Binding var showWeatherList: Bool
    @Binding var currentPage: Int
    let totalPages: Int
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: isCompact ? 20 : 25) {
                // Header section with dots and list button
                ZStack {
                    // This ensures the ZStack takes proper width
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                    
                    // Centered pagination dots
                    HStack(spacing: 4) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    
                    // Right-aligned list button
                    HStack {
                        Spacer()
                        Button(action: {
                            showWeatherList.toggle()
                        }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.trailing, 0) // Removed padding completely to move button to the edge
                }
                .padding(.top, 8)
                
                // Location and temperature content
                if location.isCurrentLocation {
                    Text("MY LOCATION")
                        .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1.5)
                        .padding(.top, 5)
                }
                
                Text(location.name)
                    .font(.system(size: isCompact ? 36 : 42, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(location.temperature)°")
                    .font(.system(size: isCompact ? 96 : 120, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.top, -10)
                
                Text(location.condition)
                    .font(.system(size: isCompact ? 24 : 28))
                    .foregroundColor(.gray)
                
                Text("H:\(location.high)° L:\(location.low)°")
                    .font(.system(size: isCompact ? 16 : 18))
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
                
                // Traffic map - responsive height
                TrafficMapView(trafficManager: trafficManager, locationName: location.name)
                    .frame(height: isCompact ? 200 : 250)
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
    let locationName: String
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.overrideUserInterfaceStyle = .dark
        mapView.pointOfInterestFilter = .includingAll
        mapView.showsBuildings = true
        mapView.showsTraffic = false // We'll use custom traffic visualization
        mapView.showsUserLocation = true
        
        // Initial map setup - region will be set in updateUIView
        
        // Initial traffic visualization
        context.coordinator.updateTrafficVisualization(mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Set the region based on location name
        if !context.coordinator.hasSetInitialRegion {
            context.coordinator.setRegionForLocation(mapView, locationName: locationName)
        }
        
        // Update traffic visualization
        context.coordinator.updateTrafficVisualization(mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TrafficMapView
        private var currentTrafficOverlays: [TrafficOverlay] = []
        private var currentVehicleAnnotations: [VehicleAnnotation] = []
        var hasSetInitialRegion = false
        
        init(_ parent: TrafficMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let trafficOverlay = overlay as? TrafficOverlay {
                return mapView.updateTrafficRenderer(for: trafficOverlay)
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let vehicleAnnotation = annotation as? VehicleAnnotation {
                return mapView.updateVehicleAnnotationView(for: vehicleAnnotation)
            }
            return nil
        }
        
        func updateTrafficVisualization(_ mapView: MKMapView) {
            // Remove existing traffic visualization
            mapView.removeOverlays(currentTrafficOverlays)
            mapView.removeAnnotations(currentVehicleAnnotations)
            currentTrafficOverlays.removeAll()
            currentVehicleAnnotations.removeAll()
            
            // Add new traffic overlays and vehicles
            for segment in parent.trafficManager.currentTrafficSegments {
                let overlay = TrafficOverlay.polyline(
                    coordinates: segment.coordinates,
                    count: segment.coordinates.count,
                    congestionLevel: segment.congestionLevel
                )
                currentTrafficOverlays.append(overlay)
                mapView.addOverlay(overlay)
                
                // Add vehicle annotations (optional)
                if segment.coordinates.count >= 2 {
                    addVehicleAnnotations(mapView, for: segment)
                }
            }
        }
        
        func setRegionForLocation(_ mapView: MKMapView, locationName: String) {
            // Convert place name to coordinates
            let geocoder = CLGeocoder()
            
            // Define default coordinates in case geocoding fails
            var latitude: Double = 37.7749
            var longitude: Double = -122.4194 // Default to San Francisco
            
            // Predefined coordinates for common locations
            switch locationName {
            case "Merced":
                latitude = 37.3022
                longitude = -120.4830
                setMapRegion(mapView, latitude: latitude, longitude: longitude)
                generateTrafficForLocation(latitude: latitude, longitude: longitude)
                hasSetInitialRegion = true
                
            case "Cupertino":
                latitude = 37.3230
                longitude = -122.0322
                setMapRegion(mapView, latitude: latitude, longitude: longitude)
                generateTrafficForLocation(latitude: latitude, longitude: longitude)
                hasSetInitialRegion = true
                
            case "New York":
                latitude = 40.7128
                longitude = -74.0060
                setMapRegion(mapView, latitude: latitude, longitude: longitude)
                generateTrafficForLocation(latitude: latitude, longitude: longitude)
                hasSetInitialRegion = true
                
            case "Alamo":
                latitude = 37.8502
                longitude = -121.9269
                setMapRegion(mapView, latitude: latitude, longitude: longitude)
                generateTrafficForLocation(latitude: latitude, longitude: longitude)
                hasSetInitialRegion = true
                
            case "Midtown":
                latitude = 40.7549
                longitude = -73.9840
                setMapRegion(mapView, latitude: latitude, longitude: longitude)
                generateTrafficForLocation(latitude: latitude, longitude: longitude)
                hasSetInitialRegion = true
                
            default:
                // For unknown locations, try to geocode
                geocoder.geocodeAddressString(locationName) { [weak self] placemarks, error in
                    if let placemark = placemarks?.first, let location = placemark.location {
                        DispatchQueue.main.async {
                            self?.setMapRegion(mapView, latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            self?.generateTrafficForLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            self?.hasSetInitialRegion = true
                        }
                    } else {
                        // If geocoding fails, use default location or user location
                        DispatchQueue.main.async {
                            if let userLocation = self?.parent.trafficManager.locationManager?.location?.coordinate {
                                self?.setMapRegion(mapView, latitude: userLocation.latitude, longitude: userLocation.longitude)
                                self?.generateTrafficForLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                            } else {
                                self?.setMapRegion(mapView, latitude: latitude, longitude: longitude)
                                self?.generateTrafficForLocation(latitude: latitude, longitude: longitude)
                            }
                            self?.hasSetInitialRegion = true
                        }
                    }
                }
            }
        }
        
        private func setMapRegion(_ mapView: MKMapView, latitude: Double, longitude: Double) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        
        private func generateTrafficForLocation(latitude: Double, longitude: Double) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            Task {
                await parent.trafficManager.generateTrafficForSearchedLocation(coordinate)
            }
        }
        
        private func addVehicleAnnotations(_ mapView: MKMapView, for segment: TrafficSegment) {
            guard segment.coordinates.count >= 2 else { return }
            
            let start = segment.coordinates[0]
            let end = segment.coordinates[segment.coordinates.count - 1]
            let direction = atan2(end.longitude - start.longitude,
                            end.latitude - start.latitude) * 180 / .pi
            
            for i in 0..<segment.vehicleCount {
                // Calculate positions along the segment
                let index = min(i, segment.coordinates.count - 1)
                let coordinate = segment.coordinates[index]
                
                let vehicle = VehicleAnnotation(
                    coordinate: coordinate,
                    direction: direction,
                    congestionLevel: segment.congestionLevel
                )
                currentVehicleAnnotations.append(vehicle)
                mapView.addAnnotation(vehicle)
            }
        }
    }
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
                        WeatherContentView(
                            location: locations[index],
                            showWeatherList: $showWeatherList,
                            currentPage: $selectedLocation,
                            totalPages: locations.count
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
