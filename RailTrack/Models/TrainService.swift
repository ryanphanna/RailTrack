import Foundation

/// Represents a train service/route for search and display.
struct TrainService: Identifiable, Codable {
    let id: String              // e.g. "VIA-55"
    var number: String          // "55"
    var name: String?           // "The Canadian"
    var trainOperator: String   // "VIA", "Amtrak", "GO"
    var origin: Station
    var destination: Station
    var scheduledDeparture: Date
    var scheduledArrival: Date
    var intermediateStops: [Station]
    var daysOfOperation: [Int]  // 1=Mon ... 7=Sun

    var operatorColor: String {
        switch trainOperator {
        case "VIA":    return "#005DAA"
        case "Amtrak": return "#004B87"
        case "GO":     return "#00A651"
        default:       return "#6B7280"
        }
    }
}
