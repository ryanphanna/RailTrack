import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !appState.isOnboarded {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .task {
            // Initial sync on app load
            await VIALiveDataService.shared.fetchAndSync(modelContext: modelContext)
            await AmtrakLiveDataService.shared.fetchAndSync(modelContext: modelContext)
            await GOLiveDataService.shared.fetchAndSync(modelContext: modelContext)
            
            // Periodically sync every 30 seconds
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                await VIALiveDataService.shared.fetchAndSync(modelContext: modelContext)
                await AmtrakLiveDataService.shared.fetchAndSync(modelContext: modelContext)
                await GOLiveDataService.shared.fetchAndSync(modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await VIALiveDataService.shared.fetchAndSync(modelContext: modelContext)
                    await AmtrakLiveDataService.shared.fetchAndSync(modelContext: modelContext)
                    await GOLiveDataService.shared.fetchAndSync(modelContext: modelContext)
                }
            }
        }
    }
}


struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, stats, social
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Trips", systemImage: "tram.fill")
                }
                .tag(Tab.home)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(Tab.stats)

            SocialView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(Tab.social)
        }
        .tint(ColorTheme.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
