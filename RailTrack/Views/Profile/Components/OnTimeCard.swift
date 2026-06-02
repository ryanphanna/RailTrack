import SwiftUI

struct OnTimeCard: View {
    let percent: Int

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: Double(percent) / 100.0)
                    .stroke(
                        LinearGradient(colors: [ColorTheme.accentGreen, ColorTheme.accentGreen.opacity(0.7)], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("\(percent)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("On-Time Performance")
                    .font(.rtHeadline)
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("Percentage of your journeys that arrived without delays.")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(ColorTheme.textTertiary.opacity(0.12), lineWidth: 1)
        )
    }
}
