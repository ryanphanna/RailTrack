import Foundation
import ActivityKit

struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic status
        var statusLabel: String        // "On Time" or "Delayed 15m"
        var delayMinutes: Int
        var isNegativeStatus: Bool     // true for delayed/cancelled
        
        var nextStationName: String    // "Cobourg"
        var estimatedArrivalTime: Date  // Live ETA
        var progressFraction: Double   // 0.0 to 1.0
    }

    // Static details
    var trainNumber: String
    var trainOperator: String          // "VIA", "Amtrak", "GO"
    var originCode: String             // "TOR"
    var destinationCode: String        // "OTT"
}
