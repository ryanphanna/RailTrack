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

    // Computed
    var scheduledDurationMinutes: Int {
        Int(scheduledArrival.timeIntervalSince(scheduledDeparture) / 60)
    }

    var isActive: Bool {
        let now = Date()
        return scheduledDeparture <= now && (actualArrival == nil)
    }

    var isUpcoming: Bool {
        scheduledDeparture > Date()
    }

    var delayMinutes: Int? {
        if case .delayed(let mins) = status { return mins }
        return nil
    }
}
