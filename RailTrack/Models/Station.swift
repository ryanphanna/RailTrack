import Foundation
import CoreLocation

struct Station: Identifiable, Codable, Hashable {
    let id: String              // GTFS stop_id, e.g. "VIA-TRTO"
    var name: String            // "Toronto Union Station"
    var shortName: String       // "Toronto"
    var code: String            // "TOR"
    var coordinate: Coordinate
    var timezone: String        // TimeZone identifier, e.g. "America/Toronto"
    var railOperator: String?       // Owning operator (if single-operator station)
    var city: String
    var country: String         // "CA", "US"

    // Convenience
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}
