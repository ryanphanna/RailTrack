import SwiftUI

struct StatsView: View {
    private let stats = MockDataService.shared.sampleStats

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Hero stats row
                        HStack(spacing: 12) {
                            StatHeroCard(value: "\(stats.totalTrips)", label: "Trips", icon: "tram.fill", color: ColorTheme.accent)
                            StatHeroCard(value: formattedKm(stats.totalKm), label: "Km", icon: "ruler", color: ColorTheme.accentGreen)
                            StatHeroCard(value: "\(stats.uniqueStations)", label: "Stations", icon: "mappin.circle.fill", color: ColorTheme.accentAmber)
                        }
                        .padding(.horizontal, 20)

                        // On-time card
                        OnTimeCard(percent: stats.onTimePercent)
                            .padding(.horizontal, 20)

                        // Streak card
                        StreakCard(current: stats.currentStreak, longest: stats.longestStreak)
                            .padding(.horizontal, 20)

                        // Operator breakdown
                        OperatorBreakdownCard(favoriteOperator: stats.favoriteOperator)
                            .padding(.horizontal, 20)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func formattedKm(_ km: Double) -> String {
        km >= 1000 ? String(format: "%.1fk", km / 1000) : "\(Int(km))"
    }
}

// MARK: - Hero Card

private struct StatHeroCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
            Text(label)
                .font(.rtCaption)
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - On-Time Card

private struct OnTimeCard: View {
    let percent: Int

    private var color: Color {
        percent >= 80 ? ColorTheme.accentGreen : percent >= 60 ? ColorTheme.accentAmber : ColorTheme.accentRed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On-Time Performance")
                    .font(.rtSubhead)
                    .foregroundStyle(ColorTheme.textPrimary)
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ColorTheme.surfaceHigh).frame(height: 8)
                    Capsule()
                        .fill(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(percent) / 100, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Streak Card

private struct StreakCard: View {
    let current: Int
    let longest: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🔥 Current Streak")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
                Text("\(current) trips")
                    .font(.rtHeadline)
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            Spacer()
            Divider().frame(height: 40).opacity(0.2)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Best Streak")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
                Text("\(longest) trips")
                    .font(.rtHeadline)
                    .foregroundStyle(ColorTheme.accentAmber)
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Operator Breakdown

private struct OperatorBreakdownCard: View {
    let favoriteOperator: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favourite Operator")
                .font(.rtSubhead)
                .foregroundStyle(ColorTheme.textPrimary)

            HStack(spacing: 10) {
                Text(favoriteOperator)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ColorTheme.operatorColor(for: favoriteOperator), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Most trips taken with")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)
                    Text(operatorFullName(favoriteOperator))
                        .font(.rtBody)
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func operatorFullName(_ op: String) -> String {
        switch op {
        case "VIA":    return "VIA Rail Canada"
        case "Amtrak": return "Amtrak"
        case "GO":     return "GO Transit"
        default:       return op
        }
    }
}

#Preview {
    StatsView()
}
