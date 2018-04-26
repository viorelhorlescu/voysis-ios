import XCTest
@testable import Voysis

class HeaderTests: XCTestCase {

    func testHeaderCreation() {
        let header = Headers(token : "token")
        XCTAssertEqual(header.xVoysisIgnoreVad,false)
        XCTAssertEqual(header.authorization,"Bearer token")
        XCTAssertNotNil(header.audioProfileId)
        XCTAssertNotNil(header.userAgent)
    }

}
