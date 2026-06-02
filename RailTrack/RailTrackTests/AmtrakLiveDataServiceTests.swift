import XCTest
@testable import RailTrack

final class AmtrakLiveDataServiceTests: XCTestCase {
    
    func testParseISO8601Date() {
        let service = AmtrakLiveDataService.shared
        let dateString = "2026-06-01T22:00:00Z"
        let date = service.parseISO8601Date(dateString)
        XCTAssertNotNil(date)
    }
    
    func testParseInvalidDateReturnsNil() {
        let service = AmtrakLiveDataService.shared
        let dateString = "invalid-date"
        let date = service.parseISO8601Date(dateString)
        XCTAssertNil(date)
    }
    
    func testParseNilDateReturnsNil() {
        let service = AmtrakLiveDataService.shared
        let date: Date? = service.parseISO8601Date(nil)
        XCTAssertNil(date)
    }
}
