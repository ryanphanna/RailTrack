import SwiftUI
import SwiftData
import CoreLocation

struct StationStamp: Identifiable {
    var id: String { station.id }
    let station: Station
    let date: Date
}

struct ProfileView: View {
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
                    EmptyProfileView(showAddTrip: $showAddTrip)
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
            if let personal = trip.personalDistanceKm {
                totalKm += personal
            } else {
                let originLoc = CLLocation(latitude: trip.origin.coordinate.latitude, longitude: trip.origin.coordinate.longitude)
                let destLoc = CLLocation(latitude: trip.destination.coordinate.latitude, longitude: trip.destination.coordinate.longitude)
                totalKm += originLoc.distance(from: destLoc) / 1000.0
            }
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

        // On-time performance — Only count completed trips to avoid "fake" 100% on active/scheduled ones
        let completedNonCancelled = trips.filter { $0.status == .completed }
        let onTimeTrips = completedNonCancelled.filter { !$0.status.isNegative }
        let onTimePercent = completedNonCancelled.isEmpty ? 100 : Int((Double(onTimeTrips.count) / Double(completedNonCancelled.count)) * 100)

        // Streaks
        let sortedPast = completedNonCancelled.sorted { $0.scheduledDeparture < $1.scheduledDeparture }
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
