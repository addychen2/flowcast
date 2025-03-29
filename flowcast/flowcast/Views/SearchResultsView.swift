import SwiftUI
import MapKit

struct SearchResultsView: View {
    let destinations: [MKMapItem]
    let onSelect: (MKMapItem) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(destinations, id: \.self) { destination in
                    Button(action: {
                        // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                     to: nil, from: nil, for: nil)
                        onSelect(destination)
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(destination.name ?? "Unknown location")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                if let address = destination.placemark.thoroughfare {
                                    Text(address)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    
                    if destination != destinations.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
