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
                            
                            // Traveler Boarding Pass Profile Card
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
                                totalHours: stats.totalHours
                            )
                            .padding(.horizontal, 20)

                            // Train Passport Stamps Collection
                            PassportStampCard(stamps: stats.stamps)
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
            .navigationTitle("Travel Stats")
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
        for op in operators {
            counts[op, default: 0] += 1
        }
        let favoriteOperator = counts.max(by: { $0.value < $1.value })?.key ?? "VIA"

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
            stamps: stamps
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Circular initials avatar with a premium gradient background
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [ColorTheme.accent, ColorTheme.accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    
                    Text(getInitials(displayName))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.rtHeadline)
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    Text("@\(username)")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "airplane.arrival")
                    .font(.system(size: 16))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .opacity(0.3)
            }
            
            Divider().opacity(0.08)
            
            // Value metrics
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISTANCE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                    Text("\(Int(totalKm)) km")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                    Text("\(totalHours) hrs")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("JOURNEYS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                    Text("\(totalTrips)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(ColorTheme.accent.opacity(0.15), lineWidth: 1)
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

// MARK: - Passport Stamp Card

private struct PassportStampCard: View {
    let stamps: [StationStamp]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Transit Passport Stamps", systemImage: "text.book.closed.fill")
                    .font(.rtSubhead)
                    .foregroundStyle(ColorTheme.textPrimary)
                Spacer()
                Text("\(stamps.count) unlocked")
                    .font(.rtCaption.bold())
                    .foregroundStyle(ColorTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ColorTheme.accent.opacity(0.12), in: Capsule())
            }
            
            if stamps.isEmpty {
                Text("Lock Screen widgets and on-time train travels will populate postage stamps for each station visited.")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(stamps) { stamp in
                        PassportStampView(stamp: stamp)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Passport Stamp View

private struct PassportStampView: View {
    let stamp: StationStamp
    @State private var rotationAngle: Double = 0.0
    
    private var inkColor: Color {
        ColorTheme.operatorColor(for: stamp.station.railOperator ?? "VIA")
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Postmark cancellation outer border
                Circle()
                    .stroke(inkColor.opacity(0.65), lineWidth: 2)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .stroke(inkColor.opacity(0.65), lineWidth: 1)
                    .frame(width: 64, height: 64)
                
                VStack(spacing: 0) {
                    Text(stamp.station.railOperator?.uppercased() ?? "RAIL")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(inkColor.opacity(0.75))
                        .tracking(1)
                    
                    Text(stamp.station.code)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(inkColor)
                        .padding(.vertical, -3)
                    
                    Text(stamp.date.formatted(.dateTime.day().month(.twoDigits).year(.twoDigits)))
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(inkColor.opacity(0.75))
                }
            }
            .rotationEffect(.degrees(rotationAngle))
            
            Text(stamp.station.shortName)
                .font(.rtCaption)
                .foregroundStyle(ColorTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            let seed = stamp.station.code.unicodeScalars.reduce(0) { $0 + Int($1.value) }
            rotationAngle = Double((seed % 14) - 7) // Deterministic tilt between -7 and +7 degrees
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
        .environmentObject(AppState())
        .modelContainer(for: TripRecord.self, inMemory: true)
}
