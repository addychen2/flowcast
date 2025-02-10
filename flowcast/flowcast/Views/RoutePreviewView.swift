import SwiftUI
import MapKit

struct RoutePreviewView: View {
    let route: MKRoute
    let source: MKMapItem
    let destinationItem: MKMapItem
    let destination: String
    let onStartNavigation: () -> Void
    @Binding var showStepsList: Bool
    @StateObject private var routeOptionsManager = RouteOptionsManager()
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var predictedTravelTime: TimeInterval
    @State private var trafficDensity: Double // 0.0 to 1.0
    
    init(route: MKRoute, source: MKMapItem, destinationItem: MKMapItem, destination: String, onStartNavigation: @escaping () -> Void, showStepsList: Binding<Bool>) {
        self.route = route
        self.source = source
        self.destinationItem = destinationItem
        self.destination = destination
        self.onStartNavigation = onStartNavigation
        self._showStepsList = showStepsList
        self._predictedTravelTime = State(initialValue: route.expectedTravelTime)
        self._trafficDensity = State(initialValue: Double.random(in: 0.3...0.9))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Route info card
            VStack(spacing: 16) {
                HStack {
                    Text(formatDuration(predictedTravelTime))
                        .font(.system(size: 24, weight: .semibold))
                    Text("(\(formatDistance(route.distance)))")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                // Time selection button
                Button(action: { showDatePicker = true }) {
                    HStack {
                        Image(systemName: "clock")
                        Text(selectedDate.formatted(date: .omitted, time: .shortened))
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Traffic prediction info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Traffic prediction")
                        .font(.system(size: 16, weight: .medium))
                    HStack {
                        TrafficDensityBar(density: trafficDensity)
                        Text(getTrafficDescription(density: trafficDensity))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 16) {
                    Button(action: onStartNavigation) {
                        Text("Start")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(24)
                    }
                    
                    SaveRouteButton(
                        sourceItem: source,
                        destinationItem: destinationItem
                    )
                    
                    Button(action: { showStepsList = true }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Steps")
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(24)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationView {
                DatePicker("Select Date and Time",
                          selection: $selectedDate,
                          in: Date()...,
                          displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding()
                .onChange(of: selectedDate) { _ in
                    updatePredictions()
                }
                .navigationTitle("Select Departure Time")
                .navigationBarItems(
                    trailing: Button("Done") {
                        showDatePicker = false
                    }
                )
            }
        }
    }
    
    private func updatePredictions() {
        // Simulate different traffic conditions based on time
        let hour = Calendar.current.component(.hour, from: selectedDate)
        let isWeekend = Calendar.current.isDateInWeekend(selectedDate)
        
        // Simulate traffic patterns
        if isWeekend {
            trafficDensity = Double.random(in: 0.3...0.6)
        } else {
            switch hour {
            case 7...9: // Morning rush
                trafficDensity = Double.random(in: 0.7...0.9)
            case 16...18: // Evening rush
                trafficDensity = Double.random(in: 0.8...1.0)
            case 11...15: // Midday
                trafficDensity = Double.random(in: 0.4...0.6)
            default: // Off-peak
                trafficDensity = Double.random(in: 0.2...0.4)
            }
        }
        
        // Adjust predicted travel time based on traffic density
        let baseTime = route.expectedTravelTime
        predictedTravelTime = baseTime * (1 + trafficDensity)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            }
            return "\(hours) hr \(remainingMinutes) min"
        }
        return "\(minutes) min"
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let miles = distance / 1609.34
        if miles < 0.1 {
            let feet = Int(distance * 3.28084)
            return "\(feet) ft"
        }
        return String(format: "%.1f mi", miles)
    }
    
    private func getTrafficDescription(density: Double) -> String {
        switch density {
        case 0.0...0.3: return "Light traffic expected"
        case 0.3...0.6: return "Moderate traffic expected"
        case 0.6...0.8: return "Heavy traffic expected"
        default: return "Severe traffic expected"
        }
    }
}

struct TrafficDensityBar: View {
    let density: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: geometry.size.width, height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(densityColor)
                    .frame(width: geometry.size.width * density, height: 8)
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
    }
    
    var densityColor: Color {
        switch density {
        case 0.0...0.3: return .green
        case 0.3...0.6: return .yellow
        case 0.6...0.8: return .orange
        default: return .red
        }
    }
}
