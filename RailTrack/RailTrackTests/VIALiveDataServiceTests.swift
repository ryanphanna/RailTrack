import XCTest
@testable import RailTrack

final class VIALiveDataServiceTests: XCTestCase {
    
    func testParseISO8601Date() {
        let service = VIALiveDataService.shared
        // VIA format: 2026-06-01T22:00:00.000
        let dateString = "2026-06-01T22:00:00.000"
        let date = service.parseISO8601Date(dateString)
        XCTAssertNotNil(date)
    }
    
    func testParseInvalidDateReturnsNil() {
        let service = VIALiveDataService.shared
        let dateString = "invalid-date"
        let date = service.parseISO8601Date(dateString)
        XCTAssertNil(date)
    }
}
