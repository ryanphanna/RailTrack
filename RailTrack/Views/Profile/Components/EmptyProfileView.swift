import SwiftUI

struct EmptyProfileView: View {
    @Binding var showAddTrip: Bool

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(ColorTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 40))
                    .foregroundStyle(ColorTheme.accent)
            }

            VStack(spacing: 12) {
                Text("Your Rail Passport")
                    .font(.rtTitle)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Track your journeys to see your travel statistics, distance covered, and collect station stamps.")
                    .font(.rtBody)
                    .foregroundStyle(ColorTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showAddTrip = true
            } label: {
                Text("Add Your First Trip")
                    .font(.rtSubhead.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(ColorTheme.accent, in: Capsule())
                    .shadow(color: ColorTheme.accent.opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 60)
    }
}
