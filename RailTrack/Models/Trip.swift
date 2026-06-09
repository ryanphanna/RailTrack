import Foundation
import CoreLocation

// MARK: - Trip Status

enum TripStatus: Codable, Equatable {
    case scheduled
    case onTime
    case delayed(minutes: Int)
    case cancelled
    case completed

    var label: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .onTime: return "On Time"
        case .delayed(let mins): return "Delayed \(mins)m"
        case .cancelled: return "Cancelled"
        case .completed: return "Completed"
        }
    }

    var isNegative: Bool {
        switch self {
        case .delayed, .cancelled: return true
        default: return false
        }
    }
}

// MARK: - Stop

struct Stop: Identifiable, Codable {
    let id: UUID
    var station: Station
    var scheduledArrival: Date?
    var scheduledDeparture: Date?
    var actualArrival: Date?
    var actualDeparture: Date?
    var platform: String?
    var isOrigin: Bool
    var isDestination: Bool

    var delayMinutes: Int? {
        guard let scheduled = scheduledArrival, let actual = actualArrival else { return nil }
        let diff = actual.timeIntervalSince(scheduled)
        return diff > 0 ? Int(diff / 60) : nil
    }
}

// MARK: - Trip

struct Trip: Identifiable, Codable {
    let id: UUID
    var trainNumber: String
    var trainOperator: String        // "VIA", "Amtrak", "GO"
    var origin: Station
    var destination: Station
    var stops: [Stop]
    var scheduledDeparture: Date
    var scheduledArrival: Date
    var actualDeparture: Date?
    var actualArrival: Date?
    var status: TripStatus
    var currentPlatform: String?
    var isPublic: Bool
    var notes: String?
    var createdAt: Date

    // Live Tracking
    var liveLatitude: Double? = nil
    var liveLongitude: Double? = nil
    var liveSpeed: Int? = nil
    var liveUpdated: Date? = nil

    // Personal Metrics
    var maxSpeedKmh: Double? = nil
    var recordedPath: [Coordinate] = []
    var personalDistanceKm: Double? = nil

    // Computed
    var serviceName: String? {
        TrainServiceCatalog.shared.getServiceName(for: trainNumber, operatorName: trainOperator)
    }

    var scheduledDurationMinutes: Int {
        Int(scheduledArrival.timeIntervalSince(scheduledDeparture) / 60)
    }

    var isActive: Bool {
        let now = Date()
        guard status != .completed, status != .cancelled else { return false }
        
        // A trip must be from today or later to be active
        let calendar = Calendar.current
        guard calendar.isDateInToday(scheduledDeparture) || scheduledDeparture > now else {
            return false
        }
        
        // A trip is active if we are between scheduled departure and a reasonable window after scheduled arrival.
        // We allow 2 hours after scheduled arrival before it's considered "stale" and moves to past journeys.
        let arrivalCutoff = scheduledArrival.addingTimeInterval(3600 * 2)
        
        return scheduledDeparture <= now && now <= arrivalCutoff && actualArrival == nil
    }

    var isUpcoming: Bool {
        guard status != .cancelled, status != .completed else { return false }
        return scheduledDeparture > Date()
    }

    var isFuture: Bool {
        // A trip is considered "future" if it is more than 24 hours away.
        // We use this to decide whether to prioritize static or live data.
        scheduledDeparture.timeIntervalSinceNow > 86400
    }

    var delayMinutes: Int? {
        if case .delayed(let mins) = status { return mins }
        return nil
    }
}
