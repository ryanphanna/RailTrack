import Foundation
import SwiftData

/// SwiftData persistent store for a trip.
/// Uses flat stored properties (no nested structs/enums with associated values)
/// and converts to/from the display-layer `Trip` struct.
@Model
final class TripRecord {

    @Attribute(.unique) var id: UUID

    // Train info
    var trainNumber: String = ""
    var trainOperator: String = ""

    // Origin (flattened)
    var originID: String = ""
    var originName: String = ""
    var originShortName: String = ""
    var originCode: String = ""
    var originLat: Double = 0.0
    var originLon: Double = 0.0
    var originTimezone: String = ""
    var originCity: String = ""
    var originCountry: String = ""

    // Destination (flattened)
    var destinationID: String = ""
    var destinationName: String = ""
    var destinationShortName: String = ""
    var destinationCode: String = ""
    var destinationLat: Double = 0.0
    var destinationLon: Double = 0.0
    var destinationTimezone: String = ""
    var destinationCity: String = ""
    var destinationCountry: String = ""

    // Status (stored as raw string + delay minutes to avoid associated-value enum)
    var statusRaw: String = "scheduled"       // "scheduled" | "onTime" | "delayed" | "cancelled" | "completed"
    var delayMinutes: Int = 0

    // Times
    var scheduledDeparture: Date = Date()
    var scheduledArrival: Date = Date()
    var actualDeparture: Date?
    var actualArrival: Date?

    // Extras
    var currentPlatform: String?
    var isPublic: Bool = false
    var notes: String?
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        trainNumber: String,
        trainOperator: String,
        origin: Station,
        destination: Station,
        scheduledDeparture: Date,
        scheduledArrival: Date,
        actualDeparture: Date? = nil,
        actualArrival: Date? = nil,
        status: TripStatus = .scheduled,
        currentPlatform: String? = nil,
        isPublic: Bool = false,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.trainNumber = trainNumber
        self.trainOperator = trainOperator

        self.originID = origin.id
        self.originName = origin.name
        self.originShortName = origin.shortName
        self.originCode = origin.code
        self.originLat = origin.coordinate.latitude
        self.originLon = origin.coordinate.longitude
        self.originTimezone = origin.timezone
        self.originCity = origin.city
        self.originCountry = origin.country

        self.destinationID = destination.id
        self.destinationName = destination.name
        self.destinationShortName = destination.shortName
        self.destinationCode = destination.code
        self.destinationLat = destination.coordinate.latitude
        self.destinationLon = destination.coordinate.longitude
        self.destinationTimezone = destination.timezone
        self.destinationCity = destination.city
        self.destinationCountry = destination.country

        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.actualDeparture = actualDeparture
        self.actualArrival = actualArrival
        self.currentPlatform = currentPlatform
        self.isPublic = isPublic
        self.notes = notes
        self.createdAt = createdAt

        switch status {
        case .scheduled:          self.statusRaw = "scheduled";  self.delayMinutes = 0
        case .onTime:             self.statusRaw = "onTime";     self.delayMinutes = 0
        case .delayed(let mins):  self.statusRaw = "delayed";    self.delayMinutes = mins
        case .cancelled:          self.statusRaw = "cancelled";  self.delayMinutes = 0
        case .completed:          self.statusRaw = "completed";  self.delayMinutes = 0
        }
    }

    // MARK: - Conversion to display model

    func toTrip() -> Trip {
        let origin = Station(
            id: originID, name: originName, shortName: originShortName, code: originCode,
            coordinate: Coordinate(latitude: originLat, longitude: originLon),
            timezone: originTimezone, railOperator: nil, city: originCity, country: originCountry
        )
        let destination = Station(
            id: destinationID, name: destinationName, shortName: destinationShortName, code: destinationCode,
            coordinate: Coordinate(latitude: destinationLat, longitude: destinationLon),
            timezone: destinationTimezone, railOperator: nil, city: destinationCity, country: destinationCountry
        )
        let status: TripStatus
        switch statusRaw {
        case "onTime":    status = .onTime
        case "delayed":   status = .delayed(minutes: delayMinutes)
        case "cancelled": status = .cancelled
        case "completed": status = .completed
        default:          status = .scheduled
        }
        return Trip(
            id: id, trainNumber: trainNumber, trainOperator: trainOperator,
            origin: origin, destination: destination, stops: [],
            scheduledDeparture: scheduledDeparture, scheduledArrival: scheduledArrival,
            actualDeparture: actualDeparture, actualArrival: actualArrival,
            status: status, currentPlatform: currentPlatform,
            isPublic: isPublic, notes: notes, createdAt: createdAt
        )
    }
}
