import Foundation

/// Stub — will be wired to Supabase once the project is created.
final class SupabaseService: ObservableObject {

    static let shared = SupabaseService()
    private init() {}

    // MARK: - Trips

    func fetchTrips() async throws -> [Trip] {
        // TODO: Replace with supabase.from("trips").select()
        try await Task.sleep(nanoseconds: 500_000_000) // simulate network
        return MockDataService.shared.sampleTrips
    }

    func saveTrip(_ trip: Trip) async throws {
        // TODO: supabase.from("trips").insert(trip)
        print("[Supabase] saveTrip: \(trip.trainNumber)")
    }

    func deleteTrip(id: UUID) async throws {
        // TODO: supabase.from("trips").delete().eq("id", id)
        print("[Supabase] deleteTrip: \(id)")
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        // TODO: supabase.auth.signIn(email: email, password: password)
        print("[Supabase] signIn")
    }

    func signUp(email: String, password: String, username: String) async throws {
        // TODO: supabase.auth.signUp(email: email, password: password)
        print("[Supabase] signUp")
    }

    func signOut() async throws {
        // TODO: supabase.auth.signOut()
        print("[Supabase] signOut")
    }
}
