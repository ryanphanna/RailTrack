import XCTest
@testable import RailTrack

final class TripLogicTests: XCTestCase {
    
    let calendar = Calendar.current
    let origin = Station(id: "TOR", name: "Toronto", shortName: "Toronto", code: "TOR", coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806), timezone: "America/Toronto", railOperator: "VIA", city: "Toronto", country: "CA")
    let destination = Station(id: "MTL", name: "Montréal", shortName: "Montréal", code: "MTL", coordinate: Coordinate(latitude: 45.5000, longitude: -73.5667), timezone: "America/Toronto", railOperator: "VIA", city: "Montréal", country: "CA")

    func testIsActiveWithBuffer() {
        let now = Date()
        
        // 1. Trip that ended 1 hour ago (should still be active due to 2hr buffer)
        let recentlyFinished = Trip(
            id: UUID(), trainNumber: "57", trainOperator: "VIA",
            origin: origin, destination: destination, stops: [],
            scheduledDeparture: now.addingTimeInterval(-10800), // 3 hrs ago
            scheduledArrival: now.addingTimeInterval(-3600),    // 1 hr ago
            status: .onTime
        )
        XCTAssertTrue(recentlyFinished.isActive, "Trip ended 1hr ago should still be active due to buffer")
        
        // 2. Trip that ended 3 hours ago (should be inactive)
        let longFinished = Trip(
            id: UUID(), trainNumber: "57", trainOperator: "VIA",
            origin: origin, destination: destination, stops: [],
            scheduledDeparture: now.addingTimeInterval(-21600), // 6 hrs ago
            scheduledArrival: now.addingTimeInterval(-10800),   // 3 hrs ago
            status: .onTime
        )
        XCTAssertFalse(longFinished.isActive, "Trip ended 3hrs ago should be inactive")
        
        // 3. Explicitly completed trip (should be inactive)
        let explicitlyFinished = Trip(
            id: UUID(), trainNumber: "57", trainOperator: "VIA",
            origin: origin, destination: destination, stops: [],
            scheduledDeparture: now.addingTimeInterval(-7200),
            scheduledArrival: now.addingTimeInterval(-3600),
            status: .completed
        )
        XCTAssertFalse(explicitlyFinished.isActive, "Explicitly completed trip should not be active")
    }
}
