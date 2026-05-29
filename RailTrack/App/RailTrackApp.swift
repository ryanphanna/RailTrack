import SwiftUI
import SwiftData

@main
struct RailTrackApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .task {
                    // Ensure permission is requested for users who skipped onboarding
                    // or upgraded from a version before notifications were wired.
                    if appState.isOnboarded {
                        await NotificationService.shared.requestPermission()
                    }
                }
        }
        .modelContainer(for: TripRecord.self)
    }
}
