import SwiftUI
import Combine

/// Central app state — auth, active user, onboarding flag.
@MainActor
final class AppState: ObservableObject {
    @Published var isOnboarded: Bool
    @Published var currentUser: UserProfile?
    @Published var isLoading: Bool = false

    init() {
        self.isOnboarded = UserDefaults.standard.bool(forKey: "isOnboarded")
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUser = profile
        } else {
            self.currentUser = nil
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "isOnboarded")
        isOnboarded = true
        Task { await NotificationService.shared.requestPermission() }
    }

    func updateProfile(username: String, displayName: String) {
        let currentId = currentUser?.id ?? UUID()
        let newProfile = UserProfile(
            id: currentId,
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarURL: currentUser?.avatarURL
        )
        self.currentUser = newProfile
        if let data = try? JSONEncoder().encode(newProfile) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }

    func signOut() {
        currentUser = nil
        isOnboarded = false
        UserDefaults.standard.set(false, forKey: "isOnboarded")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarURL: URL?
}
