import FirebaseFirestore
import CoreLocation

struct SavedTrip: Identifiable {
    var id: String
    let userId: String
    let name: String
    let sourceName: String
    let sourceLatitude: Double
    let sourceLongitude: Double
    let destinationName: String
    let destinationLatitude: Double
    let destinationLongitude: Double
    let createdAt: Date
    let frequentlyUsed: Bool
    
    var sourceCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: sourceLatitude, longitude: sourceLongitude)
    }
    
    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "sourceName": sourceName,
            "sourceLatitude": sourceLatitude,
            "sourceLongitude": sourceLongitude,
            "destinationName": destinationName,
            "destinationLatitude": destinationLatitude,
            "destinationLongitude": destinationLongitude,
            "createdAt": createdAt,
            "frequentlyUsed": frequentlyUsed
        ]
    }
    
    static func fromFirestore(_ document: QueryDocumentSnapshot) -> SavedTrip? {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let sourceName = data["sourceName"] as? String,
              let sourceLatitude = data["sourceLatitude"] as? Double,
              let sourceLongitude = data["sourceLongitude"] as? Double,
              let destinationName = data["destinationName"] as? String,
              let destinationLatitude = data["destinationLatitude"] as? Double,
              let destinationLongitude = data["destinationLongitude"] as? Double,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let frequentlyUsed = data["frequentlyUsed"] as? Bool else {
            return nil
        }
        
        return SavedTrip(
            id: document.documentID,
            userId: userId,
            name: name,
            sourceName: sourceName,
            sourceLatitude: sourceLatitude,
            sourceLongitude: sourceLongitude,
            destinationName: destinationName,
            destinationLatitude: destinationLatitude,
            destinationLongitude: destinationLongitude,
            createdAt: createdAt,
            frequentlyUsed: frequentlyUsed
        )
    }
}

enum SavedTripsError: Error {
    case fetchError
    case deleteError
    case updateError
    case saveError
    
    var localizedDescription: String {
        switch self {
        case .fetchError:
            return "Failed to fetch saved routes"
        case .deleteError:
            return "Failed to delete route"
        case .updateError:
            return "Failed to update route"
        case .saveError:
            return "Failed to save route"
        }
    }
}

@MainActor
class SavedTripsManager: ObservableObject {
    @Published var savedTrips: [SavedTrip] = []
    @Published var frequentTrips: [SavedTrip] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchSavedTrips(for userId: String) async throws {
        do {
            // Remove any existing listener
            listener?.remove()
            
            // Set up a real-time listener
            listener = db.collection("saved_trips")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error fetching saved trips: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found")
                        return
                    }
                    
                    self.savedTrips = documents.compactMap { SavedTrip.fromFirestore($0) }
                    self.frequentTrips = self.savedTrips.filter { $0.frequentlyUsed }
                }
        } catch {
            print("Error setting up trips listener: \(error)")
            throw SavedTripsError.fetchError
        }
    }
    
    func saveTrip(_ trip: SavedTrip) async throws {
        do {
            let docRef = db.collection("saved_trips").document()
            try await docRef.setData(trip.dictionary)
            print("Trip saved with ID: \(docRef.documentID)")
        } catch {
            print("Error saving trip: \(error)")
            throw SavedTripsError.saveError
        }
    }
    
    func deleteTrip(withId id: String, userId: String) async throws {
        do {
            try await db.collection("saved_trips").document(id).delete()
            // No need to fetch - listener will update
        } catch {
            print("Error deleting trip: \(error)")
            throw SavedTripsError.deleteError
        }
    }
    
    func toggleFrequent(for tripId: String, userId: String) async throws {
        guard let currentTrip = savedTrips.first(where: { $0.id == tripId }) else {
            throw SavedTripsError.updateError
        }
        
        do {
            try await db.collection("saved_trips").document(tripId).updateData([
                "frequentlyUsed": !currentTrip.frequentlyUsed
            ])
            // No need to fetch - listener will update
        } catch {
            print("Error toggling frequent status: \(error)")
            throw SavedTripsError.updateError
        }
    }
    
    deinit {
        listener?.remove()
    }
}
