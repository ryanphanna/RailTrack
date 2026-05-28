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
        self.currentUser = nil
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "isOnboarded")
        isOnboarded = true
        Task { await NotificationService.shared.requestPermission() }
    }

    func signOut() {
        currentUser = nil
        isOnboarded = false
        UserDefaults.standard.set(false, forKey: "isOnboarded")
    }
}

struct UserProfile: Identifiable, Codable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarURL: URL?
}
