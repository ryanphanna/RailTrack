import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "tram.fill",
            color: Color(hex: "#005DAA"),
            title: "Track Your Trains",
            subtitle: "Real-time position, delays, and platform changes — all in one place."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            color: Color(hex: "#FF6B35"),
            title: "Instant Alerts",
            subtitle: "Get notified the moment your train is delayed or your platform changes."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            color: Color(hex: "#00A651"),
            title: "Your Rail Stats",
            subtitle: "Track distance, on-time rate, streaks, and favourite routes over time."
        ),
        OnboardingPage(
            icon: "person.2.fill",
            color: Color(hex: "#A855F7"),
            title: "Travel with Friends",
            subtitle: "See where your friends are on their journeys in real time."
        )
    ]

    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom controls
                VStack(spacing: 24) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? pages[currentPage].color : ColorTheme.textTertiary)
                                .frame(width: i == currentPage ? 22 : 7, height: 7)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // CTA button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            appState.completeOnboarding()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .font(.rtSubhead)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.8)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                    }
                    .animation(.easeInOut, value: currentPage)

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            appState.completeOnboarding()
                        }
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)
                    } else {
                        Color.clear.frame(height: 20)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page

struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon blob
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 110, height: 110)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(page.color)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.rtTitle)
                    .foregroundStyle(ColorTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.rtBody)
                    .foregroundStyle(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
