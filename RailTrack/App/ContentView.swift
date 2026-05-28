import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !appState.isOnboarded {
            OnboardingView()
        } else {
            MainTabView()
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
