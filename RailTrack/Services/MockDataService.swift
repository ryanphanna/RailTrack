import Foundation

/// Provides realistic mock trips for UI development and SwiftUI previews.
/// Swap this out for SupabaseService once the backend is wired up.
final class MockDataService {

    static let shared = MockDataService()
    private init() {}

    // MARK: - Stations

    let torontoUnion = Station(
        id: "VIA-TRTO", name: "Toronto Union Station", shortName: "Toronto",
        code: "TOR", coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806),
        timezone: "America/Toronto", railOperator: nil, city: "Toronto", country: "CA"
    )
    let kingstonStation = Station(
        id: "VIA-KGON", name: "Kingston Station", shortName: "Kingston",
        code: "KGN", coordinate: Coordinate(latitude: 44.2312, longitude: -76.5010),
        timezone: "America/Toronto", railOperator: nil, city: "Kingston", country: "CA"
    )
    let ottawaStation = Station(
        id: "VIA-OTTW", name: "Ottawa Station", shortName: "Ottawa",
        code: "OTT", coordinate: Coordinate(latitude: 45.4168, longitude: -75.6561),
        timezone: "America/Toronto", railOperator: nil, city: "Ottawa", country: "CA"
    )
    let montrealCentral = Station(
        id: "VIA-MTRL", name: "Montréal Central Station", shortName: "Montréal",
        code: "MTL", coordinate: Coordinate(latitude: 45.4994, longitude: -73.5686),
        timezone: "America/Toronto", railOperator: nil, city: "Montréal", country: "CA"
    )
    let newYorkPenn = Station(
        id: "AMTRAK-NYP", name: "New York Penn Station", shortName: "New York",
        code: "NYP", coordinate: Coordinate(latitude: 40.7506, longitude: -73.9971),
        timezone: "America/New_York", railOperator: "Amtrak", city: "New York", country: "US"
    )

    // MARK: - Sample Trips

    var sampleTrips: [Trip] {
        let now = Date()
        let cal = Calendar.current

        // Active trip: VIA 60, Toronto → Ottawa, currently delayed 12m
        let trip1 = Trip(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            trainNumber: "60",
            trainOperator: "VIA",
            origin: torontoUnion,
            destination: ottawaStation,
            stops: [
                Stop(id: UUID(), station: torontoUnion,
                     scheduledArrival: nil,
                     scheduledDeparture: cal.date(byAdding: .minute, value: -90, to: now),
                     actualDeparture: cal.date(byAdding: .minute, value: -78, to: now),
                     platform: "8", isOrigin: true, isDestination: false),
                Stop(id: UUID(), station: kingstonStation,
                     scheduledArrival: cal.date(byAdding: .minute, value: 30, to: now),
                     scheduledDeparture: cal.date(byAdding: .minute, value: 35, to: now),
                     platform: nil, isOrigin: false, isDestination: false),
                Stop(id: UUID(), station: ottawaStation,
                     scheduledArrival: cal.date(byAdding: .minute, value: 150, to: now),
                     scheduledDeparture: nil, platform: nil,
                     isOrigin: false, isDestination: true)
            ],
            scheduledDeparture: cal.date(byAdding: .minute, value: -90, to: now)!,
            scheduledArrival: cal.date(byAdding: .minute, value: 150, to: now)!,
            actualDeparture: cal.date(byAdding: .minute, value: -78, to: now),
            actualArrival: nil,
            status: .delayed(minutes: 12),
            currentPlatform: "8",
            isPublic: true,
            notes: nil,
            createdAt: cal.date(byAdding: .day, value: -3, to: now)!
        )

        // Upcoming trip: VIA 33, Toronto → Montréal, tomorrow morning
        let departureTomorrow = cal.date(bySettingHour: 9, minute: 0, second: 0,
                                          of: cal.date(byAdding: .day, value: 1, to: now)!)!
        let trip2 = Trip(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            trainNumber: "33",
            trainOperator: "VIA",
            origin: torontoUnion,
            destination: montrealCentral,
            stops: [],
            scheduledDeparture: departureTomorrow,
            scheduledArrival: cal.date(byAdding: .minute, value: 330, to: departureTomorrow)!,
            actualDeparture: nil, actualArrival: nil,
            status: .scheduled,
            currentPlatform: nil, isPublic: false,
            notes: "Business trip", createdAt: now
        )

        // Past trip: Amtrak Maple Leaf, Toronto → New York
        let pastDep = cal.date(byAdding: .day, value: -7, to: now)!
        let trip3 = Trip(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            trainNumber: "63",
            trainOperator: "Amtrak",
            origin: torontoUnion,
            destination: newYorkPenn,
            stops: [],
            scheduledDeparture: pastDep,
            scheduledArrival: cal.date(byAdding: .hour, value: 12, to: pastDep)!,
            actualDeparture: pastDep,
            actualArrival: cal.date(byAdding: .minute, value: 745, to: pastDep),
            status: .completed,
            currentPlatform: nil, isPublic: false,
            notes: nil, createdAt: cal.date(byAdding: .day, value: -10, to: now)!
        )

        return [trip1, trip2, trip3]
    }

    // MARK: - Sample Alerts

    var sampleAlerts: [TrainAlert] {
        [
            TrainAlert(
                id: UUID(), tripID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                type: .delay, message: "VIA 60 is running approximately 12 minutes late due to freight traffic near Cobourg.",
                issuedAt: Date(), isRead: false
            ),
            TrainAlert(
                id: UUID(), tripID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                type: .platformChange, message: "Platform changed from 7 to 8.",
                issuedAt: Date().addingTimeInterval(-600), isRead: true
            )
        ]
    }

    // MARK: - User Stats (mock)

    struct UserStats {
        var totalTrips: Int
        var totalKm: Double
        var uniqueStations: Int
        var onTimePercent: Int
        var currentStreak: Int
        var longestStreak: Int
        var favoriteOperator: String
    }

    var sampleStats: UserStats {
        UserStats(
            totalTrips: 47,
            totalKm: 12_340,
            uniqueStations: 23,
            onTimePercent: 68,
            currentStreak: 5,
            longestStreak: 12,
            favoriteOperator: "VIA"
        )
    }
}
