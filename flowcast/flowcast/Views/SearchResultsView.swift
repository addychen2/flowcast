import SwiftUI
import MapKit

struct SearchResultsView: View {
    let destinations: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(destinations, id: \.hash) { destination in
                    Button(action: {
                        onSelect(destination)
                    }) {
                        VStack(alignment: .leading) {
                            Text(destination.name ?? "Unknown location")
                                .font(.headline)
                            if let address = destination.placemark.thoroughfare {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
