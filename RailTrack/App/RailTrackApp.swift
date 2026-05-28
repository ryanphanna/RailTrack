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
        }
        .modelContainer(for: TripRecord.self)
    }
}
