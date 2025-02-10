import SwiftUI
import MapKit

struct SaveRouteButton: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var tripsManager = SavedTripsManager()
    @State private var showingSaveDialog = false
    @State private var routeName = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let sourceItem: MKMapItem
    let destinationItem: MKMapItem
    
    var body: some View {
        Button(action: {
            showingSaveDialog = true
        }) {
            HStack {
                Image(systemName: "bookmark")
                Text("Save Route")
            }
            .font(.system(size: 16))
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(24)
        }
        .alert("Save Route", isPresented: $showingSaveDialog) {
            TextField("Route Name", text: $routeName)
            
            Button("Cancel", role: .cancel) {
                routeName = ""
            }
            
            Button("Save") {
                saveRoute()
            }
            .disabled(routeName.isEmpty || isSaving)
            
        } message: {
            Text("Enter a name for this route")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveRoute() {
        guard let userId = authManager.user?.uid else {
            errorMessage = "You must be signed in to save routes"
            showError = true
            return
        }
        
        isSaving = true
        
        let trip = SavedTrip(
            id: UUID().uuidString,
            userId: userId,
            name: routeName,
            sourceName: sourceItem.name ?? "Unknown Location",
            sourceLatitude: sourceItem.placemark.coordinate.latitude,
            sourceLongitude: sourceItem.placemark.coordinate.longitude,
            destinationName: destinationItem.name ?? "Unknown Location",
            destinationLatitude: destinationItem.placemark.coordinate.latitude,
            destinationLongitude: destinationItem.placemark.coordinate.longitude,
            createdAt: Date(),
            frequentlyUsed: false
        )
        
        Task {
            do {
                try await tripsManager.saveTrip(trip)
                isSaving = false
                routeName = ""
            } catch {
                errorMessage = "Failed to save route: \(error.localizedDescription)"
                showError = true
                isSaving = false
            }
        }
    }
}
