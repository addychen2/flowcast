import SwiftUI
import MapKit

struct SavedTripsView: View {
    @StateObject private var tripsManager = SavedTripsManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var routeManager: RouteManager
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading saved routes...")
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            } else if tripsManager.savedTrips.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No saved routes yet")
                        .font(.headline)
                    Text("Your saved routes will appear here")
                        .foregroundColor(.gray)
                }
            } else {
                List {
                    if !tripsManager.frequentTrips.isEmpty {
                        Section(header: Text("FREQUENT ROUTES")) {
                            ForEach(tripsManager.frequentTrips) { trip in
                                SavedTripRow(trip: trip) {
                                    selectTrip(trip)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteTrip(trip)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFrequent(trip)
                                    } label: {
                                        Label("Unfavorite", systemImage: "star.slash")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("ALL SAVED ROUTES")) {
                        ForEach(tripsManager.savedTrips) { trip in
                            SavedTripRow(trip: trip) {
                                selectTrip(trip)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTrip(trip)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    toggleFrequent(trip)
                                } label: {
                                    Label(trip.frequentlyUsed ? "Unfavorite" : "Favorite",
                                          systemImage: trip.frequentlyUsed ? "star.slash" : "star")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .refreshable {
                    do {
                        try await fetchTrips()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
        .navigationTitle("Saved Routes")
        .navigationBarBackButtonHidden(false)
        .task {
            do {
                try await fetchTrips()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                Task {
                    do {
                        try await fetchTrips()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func fetchTrips() async throws {
        guard let userId = authManager.user?.uid else {
            throw SavedTripsError.fetchError
        }
        
        isLoading = true
        do {
            try await tripsManager.fetchSavedTrips(for: userId)
            isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }
    
    private func selectTrip(_ trip: SavedTrip) {
        let destinationPlacemark = MKPlacemark(
            coordinate: trip.destinationCoordinate
        )
        let destination = MKMapItem(placemark: destinationPlacemark)
        destination.name = trip.destinationName
        
        routeManager.setDestination(destination)
        dismiss()
    }
    
    private func deleteTrip(_ trip: SavedTrip) {
        guard let userId = authManager.user?.uid else { return }
        Task {
            do {
                try await tripsManager.deleteTrip(withId: trip.id, userId: userId)
            } catch {
                errorMessage = "Failed to delete route: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func toggleFrequent(_ trip: SavedTrip) {
        guard let userId = authManager.user?.uid else { return }
        Task {
            do {
                try await tripsManager.toggleFrequent(for: trip.id, userId: userId)
            } catch {
                errorMessage = "Failed to update route: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

struct SavedTripRow: View {
    let trip: SavedTrip
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: trip.frequentlyUsed ? "star.fill" : "mappin.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(trip.frequentlyUsed ? .orange : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(trip.destinationName)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
    }
}
