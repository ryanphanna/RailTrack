import SwiftUI
import SwiftData
import CoreLocation

struct StationStamp: Identifiable {
    var id: String { station.id }
    let station: Station
    let date: Date
}

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query(sort: \TripRecord.scheduledDeparture, order: .forward) private var records: [TripRecord]
    @State private var showAddTrip = false

    private struct ComputedStats {
        var totalTrips: Int
        var totalKm: Double
        var totalHours: Int
        var uniqueStations: Int
        var onTimePercent: Int
        var currentStreak: Int
        var longestStreak: Int
        var favoriteOperator: String
        var stamps: [StationStamp]
        var uniqueCountries: Int
        var onTimeCount: Int
        var cancelledCount: Int
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

                            // Profile + Stats card
                            let userProfile = appState.currentUser ?? UserProfile(
                                id: UUID(),
                                username: "traveler",
                                displayName: "Rail Traveler"
                            )

                            BoardingPassProfileCard(
                                displayName: userProfile.displayName,
                                username: userProfile.username,
                                totalTrips: stats.totalTrips,
                                totalKm: stats.totalKm,
                                totalHours: stats.totalHours,
                                uniqueStations: stats.uniqueStations,
                                onTimeCount: stats.onTimeCount,
                                currentStreak: stats.currentStreak,
                                longestStreak: stats.longestStreak,
                                uniqueCountries: stats.uniqueCountries,
                                cancelledCount: stats.cancelledCount
                            )
                            .padding(.horizontal, 20)

                            // Scattered passport stamps
                            PassportStampCard(stamps: stats.stamps)
                                .padding(.horizontal, 20)

                            // On-time card
                            OnTimeCard(percent: stats.onTimePercent)
                                .padding(.horizontal, 20)

                            Color.clear.frame(height: 20)
                        }
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddTrip) {
                AddTripView()
            }
        }
    }

    private func computeStats(from records: [TripRecord]) -> ComputedStats {
        let trips = records.map { $0.toTrip() }
        let completedOrPastTrips = trips.filter { !$0.isUpcoming }
        let validTrips = trips.filter { $0.status != .cancelled }
        let cancelledCount = trips.filter { $0.status == .cancelled }.count

        // Distance in km
        var totalKm: Double = 0.0
        for trip in validTrips {
            let originLoc = CLLocation(latitude: trip.origin.coordinate.latitude, longitude: trip.origin.coordinate.longitude)
            let destLoc = CLLocation(latitude: trip.destination.coordinate.latitude, longitude: trip.destination.coordinate.longitude)
            totalKm += originLoc.distance(from: destLoc) / 1000.0
        }

        // Travel Duration in hours
        var totalSeconds: TimeInterval = 0
        for trip in validTrips {
            let dep = trip.actualDeparture ?? trip.scheduledDeparture
            let arr = trip.actualArrival ?? trip.scheduledArrival
            totalSeconds += arr.timeIntervalSince(dep)
        }
        let totalHours = max(1, Int(totalSeconds / 3600))

        // Unique stations
        var stationIDs = Set<String>()
        for trip in validTrips {
            stationIDs.insert(trip.origin.id)
            stationIDs.insert(trip.destination.id)
        }
        let uniqueStations = stationIDs.count

        // On-time performance
        let pastNonCancelled = completedOrPastTrips.filter { $0.status != .cancelled }
        let onTimeTrips = pastNonCancelled.filter { !$0.status.isNegative }
        let onTimePercent = pastNonCancelled.isEmpty ? 100 : Int((Double(onTimeTrips.count) / Double(pastNonCancelled.count)) * 100)

        // Streaks
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
        for op in operators { counts[op, default: 0] += 1 }
        let favoriteOperator = counts.max(by: { $0.value < $1.value })?.key ?? "VIA"

        // Unique countries
        var stationObjs: [Station] = []
        for trip in validTrips {
            stationObjs.append(trip.origin)
            stationObjs.append(trip.destination)
        }
        let uniqueCountries = Set(stationObjs.map { $0.country }).count

        // Build passport stamps from visited stations
        var stationVisits: [String: Date] = [:]
        for trip in validTrips {
            let dep = trip.actualDeparture ?? trip.scheduledDeparture
            stationVisits[trip.origin.id] = min(stationVisits[trip.origin.id] ?? .distantFuture, dep)
            stationVisits[trip.destination.id] = min(stationVisits[trip.destination.id] ?? .distantFuture, dep)
        }

        var stamps: [StationStamp] = []
        for (stationId, date) in stationVisits {
            if let station = StationDatabase.shared.stations.first(where: { $0.id == stationId }) {
                stamps.append(StationStamp(station: station, date: date))
            } else {
                let parts = stationId.split(separator: "-")
                let op = String(parts.first ?? "VIA")
                let code = String(parts.last ?? "TOR")
                let station = Station(
                    id: stationId,
                    name: code,
                    shortName: code,
                    code: code,
                    coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806),
                    timezone: "America/Toronto",
                    railOperator: op,
                    city: code,
                    country: op == "Amtrak" ? "US" : "CA"
                )
                stamps.append(StationStamp(station: station, date: date))
            }
        }
        stamps.sort { $0.date > $1.date }

        return ComputedStats(
            totalTrips: validTrips.count,
            totalKm: totalKm,
            totalHours: totalHours,
            uniqueStations: uniqueStations,
            onTimePercent: onTimePercent,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            favoriteOperator: favoriteOperator,
            stamps: stamps,
            uniqueCountries: uniqueCountries,
            onTimeCount: onTimeTrips.count,
            cancelledCount: cancelledCount
        )
    }
}

// MARK: - Boarding Pass Profile Card

private struct BoardingPassProfileCard: View {
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
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                            Text("\(Int(totalKm)) km")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
                            Text("\(totalHours) hrs")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
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

            // Compact icon-stat grid (App in the Air bottom row)
            HStack(spacing: 0) {
                IconStatCell(icon: "tram.fill", value: totalTrips, label: nil)
                Divider().frame(height: 28).opacity(0.15)
                IconStatCell(icon: "building.2.fill", value: uniqueStations, label: nil)
                Divider().frame(height: 28).opacity(0.15)
                IconStatCell(icon: "flag.fill", value: uniqueCountries, label: nil)
                Divider().frame(height: 28).opacity(0.15)
                IconStatCell(icon: "checkmark.seal.fill", value: onTimeCount, label: nil)
                Divider().frame(height: 28).opacity(0.15)
                IconStatCell(icon: "flame.fill", value: currentStreak, label: nil)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
        }
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(ColorTheme.accent.opacity(0.12), lineWidth: 1)
        )
    }

    private func getInitials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Icon Stat Cell

private struct IconStatCell: View {
    let icon: String
    let value: Int
    let label: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(ColorTheme.textTertiary.opacity(0.7))
            Text("\(value)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(ColorTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Passport Stamp Card

private struct PassportStampCard: View {
    let stamps: [StationStamp]

    // For the two-column header numbers (Special / Countries)
    private var viaCount: Int { stamps.filter { $0.station.railOperator == "VIA" }.count }
    private var countryCount: Int { Set(stamps.compactMap { $0.station.country }).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header row: two big stats + title (App in the Air style)
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stations")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ColorTheme.textSecondary)
                    Text("\(stamps.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Countries")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ColorTheme.textSecondary)
                    Text("\(countryCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if stamps.isEmpty {
                Text("Complete trips to earn passport stamps for each station visited.")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            } else {
                // Freeform scattered stamp layout
                ScatteredStampsCanvas(stamps: stamps)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
            }
        }
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Scattered Stamps Canvas

private struct ScatteredStampsCanvas: View {
    let stamps: [StationStamp]

    // Deterministic offset/rotation per stamp using its code as seed
    private func seed(for stamp: StationStamp) -> Int {
        stamp.station.code.unicodeScalars.reduce(0) { $0 + Int($1.value) }
    }

    private func rotation(for stamp: StationStamp) -> Double {
        let s = seed(for: stamp)
        return Double((s % 22) - 11) // -11° to +11°
    }

    private func xOffset(for stamp: StationStamp, in width: CGFloat) -> CGFloat {
        let s = seed(for: stamp)
        let band = CGFloat((s * 37 + 13) % 100) / 100.0 // 0…1
        return -width * 0.3 + band * width * 0.6
    }

    private func yOffset(for stamp: StationStamp, index: Int) -> CGFloat {
        let s = seed(for: stamp)
        let jitter = CGFloat((s * 17 + index * 31) % 24) - 12
        return jitter
    }

    var body: some View {
        GeometryReader { geo in
            let displayStamps = Array(stamps.prefix(9)) // Show up to 9
            let stampSize: CGFloat = 82
            let columns = 3
            let colWidth = geo.size.width / CGFloat(columns)

            ZStack {
                ForEach(Array(displayStamps.enumerated()), id: \.element.id) { index, stamp in
                    let col = index % columns
                    let row = index / columns
                    let baseX = colWidth * CGFloat(col) + colWidth / 2
                    let baseY = stampSize * 1.1 * CGFloat(row) + stampSize / 2
                    let extraX = xOffset(for: stamp, in: colWidth * 0.25)
                    let extraY = yOffset(for: stamp, index: index)

                    PassportStampView(stamp: stamp)
                        .frame(width: stampSize, height: stampSize + 22)
                        .rotationEffect(.degrees(rotation(for: stamp)))
                        .position(x: baseX + extraX, y: baseY + extraY)
                        .zIndex(Double(displayStamps.count - index))
                }
            }
            .frame(height: CGFloat(((displayStamps.count - 1) / columns + 1)) * stampSize * 1.15 + 16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Passport Stamp View

private struct PassportStampView: View {
    let stamp: StationStamp

    private var inkColor: Color {
        ColorTheme.operatorColor(for: stamp.station.railOperator ?? "VIA")
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(inkColor.opacity(0.55), lineWidth: 2.5)
                    .frame(width: 68, height: 68)
                // Inner ring
                Circle()
                    .stroke(inkColor.opacity(0.35), lineWidth: 1)
                    .frame(width: 58, height: 58)

                // Stamp content
                VStack(spacing: 0) {
                    Text(stamp.station.railOperator?.uppercased() ?? "RAIL")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(inkColor.opacity(0.7))
                        .tracking(1.2)

                    Text(stamp.station.code)
                        .font(.system(size: 17, weight: .black, design: .monospaced))
                        .foregroundStyle(inkColor)
                        .padding(.vertical, -2)

                    Text(stamp.date.formatted(.dateTime.day().month(.twoDigits).year(.twoDigits)))
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(inkColor.opacity(0.65))
                }
            }

            Text(stamp.station.shortName)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(ColorTheme.textSecondary)
                .lineLimit(1)
        }
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
        .environmentObject(AppState())
        .modelContainer(for: TripRecord.self, inMemory: true)
}
