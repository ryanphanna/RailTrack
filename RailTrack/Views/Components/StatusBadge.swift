import SwiftUI

struct StatusBadge: View {
    let status: TripStatus

    private var label: String { status.label }

    private var color: Color {
        switch status {
        case .onTime:           return ColorTheme.accentGreen
        case .delayed:          return ColorTheme.accentAmber
        case .cancelled:        return ColorTheme.accentRed
        case .scheduled:        return ColorTheme.textSecondary
        case .completed:        return ColorTheme.textTertiary
        }
    }

    private var icon: String {
        switch status {
        case .onTime:           return "checkmark.circle.fill"
        case .delayed:          return "clock.badge.exclamationmark.fill"
        case .cancelled:        return "xmark.circle.fill"
        case .scheduled:        return "calendar"
        case .completed:        return "checkmark.seal.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.rtCaption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15), in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(status: .onTime)
        StatusBadge(status: .delayed(minutes: 14))
        StatusBadge(status: .cancelled)
        StatusBadge(status: .scheduled)
        StatusBadge(status: .completed)
    }
    .padding()
    .background(ColorTheme.background)
}
