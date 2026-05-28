import SwiftUI

/// A prominent amber banner shown on TripDetailView when the train is delayed.
struct DelayBanner: View {
    let delayMinutes: Int
    let message: String?

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ColorTheme.accentAmber)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Running \(delayMinutes) minutes late")
                        .font(.rtSubhead)
                        .foregroundStyle(ColorTheme.accentAmber)
                    if let msg = message, isExpanded {
                        Text(msg)
                            .font(.rtBody)
                            .foregroundStyle(ColorTheme.textSecondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ColorTheme.textTertiary)
            }
        }
        .padding(14)
        .background(ColorTheme.accentAmber.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(ColorTheme.accentAmber.opacity(0.3), lineWidth: 1))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DelayBanner(delayMinutes: 12, message: "Delayed due to freight traffic near Cobourg.")
        DelayBanner(delayMinutes: 45, message: nil)
    }
    .padding()
    .background(ColorTheme.background)
}
