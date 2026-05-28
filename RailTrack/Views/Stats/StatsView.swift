import SwiftUI
import SwiftData
import CoreLocation

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripRecord.scheduledDeparture, order: .forward) private var records: [TripRecord]
    @State private var showAddTrip = false

    private struct ComputedStats {
        var totalTrips: Int
        var totalKm: Double
        var uniqueStations: Int
        var onTimePercent: Int
        var currentStreak: Int
        var longestStreak: Int
        var favoriteOperator: String
    }

    private var stats: ComputedStats {
        computeStats(from: records)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                if records.isEmpty {
                    EmptyStatsView(showAddTrip: $showAddTrip)
                } else {
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
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddTrip) {
                AddTripView()
            }
        }
    }

    private func formattedKm(_ km: Double) -> String {
        km >= 1000 ? String(format: "%.1fk", km / 1000) : "\(Int(km))"
    }

    private func computeStats(from records: [TripRecord]) -> ComputedStats {
        let trips = records.map { $0.toTrip() }
        let completedOrPastTrips = trips.filter { !$0.isUpcoming }
        let validTrips = trips.filter { $0.status != .cancelled }

        // Distance in km
        var totalKm: Double = 0.0
        for trip in validTrips {
            let originLoc = CLLocation(latitude: trip.origin.coordinate.latitude, longitude: trip.origin.coordinate.longitude)
            let destLoc = CLLocation(latitude: trip.destination.coordinate.latitude, longitude: trip.destination.coordinate.longitude)
            totalKm += originLoc.distance(from: destLoc) / 1000.0
        }

        // Unique stations
        var stationIDs = Set<String>()
        for trip in validTrips {
            stationIDs.insert(trip.origin.id)
            stationIDs.insert(trip.destination.id)
        }
        let uniqueStations = stationIDs.count

        // On-time performance: percentage of past/completed trips that were on-time
        let pastNonCancelled = completedOrPastTrips.filter { $0.status != .cancelled }
        let onTimeTrips = pastNonCancelled.filter { !$0.status.isNegative }
        let onTimePercent = pastNonCancelled.isEmpty ? 100 : Int((Double(onTimeTrips.count) / Double(pastNonCancelled.count)) * 100)

        // Streaks: consecutive on-time trips in pastNonCancelled sorted by departure
        let sortedPast = pastNonCancelled.sorted { $0.scheduledDeparture < $1.scheduledDeparture }
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0

        for trip in sortedPast {
            if !trip.status.isNegative {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }
        // Current streak is the streak ending at the last past trip
        for trip in sortedPast.reversed() {
            if !trip.status.isNegative {
                currentStreak += 1
            } else {
                break
            }
        }

        // Favorite Operator
        let operators = validTrips.map { $0.trainOperator }
        var counts: [String: Int] = [:]
        for op in operators {
            counts[op, default: 0] += 1
        }
        let favoriteOperator = counts.max(by: { $0.value < $1.value })?.key ?? "VIA"

        return ComputedStats(
            totalTrips: validTrips.count,
            totalKm: totalKm,
            uniqueStations: uniqueStations,
            onTimePercent: onTimePercent,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            favoriteOperator: favoriteOperator
        )
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

// MARK: - Empty Stats View

private struct EmptyStatsView: View {
    @Binding var showAddTrip: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(ColorTheme.textTertiary)

            Text("No Journeys Yet")
                .font(.rtHeadline)
                .foregroundStyle(ColorTheme.textPrimary)

            Text("Tracked trips and completed train journeys will compile your distances, streaks, and carrier breakdown here.")
                .font(.rtBody)
                .foregroundStyle(ColorTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                showAddTrip = true
            } label: {
                Label("Add Your First Trip", systemImage: "plus")
                    .font(.rtSubhead)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(ColorTheme.accent, in: Capsule())
            }
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: TripRecord.self, inMemory: true)
}
