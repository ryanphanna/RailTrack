import XCTest
@testable import RailTrack

final class StationDatabaseTests: XCTestCase {
    
    func testSearchEmptyQueryReturnsAllStations() {
        let db = StationDatabase.shared
        let results = db.search("")
        XCTAssertEqual(results.count, db.stations.count)
    }
    
    func testSearchByName() {
        let db = StationDatabase.shared
        let results = db.search("Toronto")
        XCTAssertTrue(results.contains { $0.code == "TOR" })
    }
    
    func testSearchByCode() {
        let db = StationDatabase.shared
        let results = db.search("NYP")
        XCTAssertTrue(results.contains { $0.name == "New York Penn Station" })
    }
    
    func testStationLookupWithMatch() {
        let db = StationDatabase.shared
        let station = db.station(for: "OTT", operator: "VIA")
        XCTAssertEqual(station.code, "OTT")
        XCTAssertEqual(station.railOperator, "VIA")
    }
    
    func testStationLookupWithFallback() {
        let db = StationDatabase.shared
        let station = db.station(for: "UnknownCity", operator: "Amtrak")
        XCTAssertEqual(station.name, "UnknownCity")
        XCTAssertEqual(station.railOperator, "Amtrak")
        XCTAssertEqual(station.country, "US")
    }
}
