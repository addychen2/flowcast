import SwiftUI

struct WeatherListView: View {
    @Environment(\.dismiss) private var dismiss
    let locations: [WeatherLocation]
    @Binding var selectedLocation: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                    Button(action: {
                        selectedLocation = index
                        isPresented = false
                    }) {
                        WeatherLocationCell(
                            location: location.name,
                            temperature: "\(location.temperature)°",
                            condition: location.condition,
                            high: "\(location.high)°",
                            low: "\(location.low)°",
                            isCurrentLocation: location.isCurrentLocation
                        )
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .preferredColorScheme(.dark)
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct WeatherLocationCell: View {
    let location: String
    let temperature: String
    let condition: String
    let high: String
    let low: String
    var isCurrentLocation: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(location)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    if isCurrentLocation {
                        Text("My Location")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Text(condition)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(temperature)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Text("H:\(high)")
                    Text("L:\(low)")
                }
                .font(.system(size: 14))
                .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    WeatherListView(
        locations: [
            WeatherLocation(name: "Merced", temperature: 48, condition: "Cloudy", high: 54, low: 38, isCurrentLocation: true),
            WeatherLocation(name: "Cupertino", temperature: 48, condition: "Cloudy", high: 56, low: 42, isCurrentLocation: false)
        ],
        selectedLocation: .constant(0),
        isPresented: .constant(true)
    )
}
