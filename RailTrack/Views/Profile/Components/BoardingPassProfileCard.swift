import SwiftUI

struct BoardingPassProfileCard: View {
    let displayName: String
    let username: String
    let totalTrips: Int
    let totalKm: Double
    let totalHours: Int
    let uniqueStations: Int
    let onTimeCount: Int
    let currentStreak: Int
    let longestStreak: Int
    let uniqueCountries: Int
    let cancelledCount: Int

    var body: some View {
        VStack(spacing: 0) {
            // Top: Avatar + name + big stats row
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [ColorTheme.accent, ColorTheme.accent.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 52, height: 52)
                        Text(getInitials(displayName))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayName)
                            .font(.rtHeadline)
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("RailTrack")
                            .font(.rtCaption)
                            .foregroundStyle(ColorTheme.textTertiary)
                    }

                    Spacer()
                }

                // Primary big stats — distance · hours with chevron (App in the Air style)
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Statistics")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ColorTheme.textTertiary)
                        HStack(alignment: .firstTextBaseline, spacing: 20) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(Int(totalKm))")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Text("KM")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(totalHours)")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Text("HRS")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ColorTheme.textTertiary.opacity(0.5))
                }
            }
            .padding(20)

            // Divider with dashed feel
            Rectangle()
                .fill(ColorTheme.textTertiary.opacity(0.08))
                .frame(height: 1)

            // Compact icon-stat grid
            HStack(spacing: 0) {
                IconStatCell(icon: "tram.fill", value: totalTrips, label: "Trips")
                divider
                IconStatCell(icon: "building.2.fill", value: uniqueStations, label: "Stations")
                divider
                IconStatCell(icon: "flag.fill", value: uniqueCountries, label: "Regions")
                divider
                IconStatCell(icon: "checkmark.seal.fill", value: onTimeCount, label: "On-Time")
                divider
                IconStatCell(icon: "flame.fill", value: currentStreak, label: "Streak")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(ColorTheme.textTertiary.opacity(0.12), lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(ColorTheme.textTertiary.opacity(0.15))
            .frame(width: 1, height: 24)
    }

    private func getInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct IconStatCell: View {
    let icon: String
    let value: Int
    let label: String?

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(ColorTheme.accent)
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
            if let label = label {
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
