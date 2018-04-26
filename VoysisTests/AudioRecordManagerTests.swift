import XCTest
@testable import VoysisSdk

class AudioRecordManagerTests: XCTestCase {
    private var manager: AudioRecorderManagerImpl!

    override func setUp() {
        super.setUp()
        manager = AudioRecorderManagerImpl()
    }

    override func tearDown() {
        super.tearDown()
        manager = nil
    }

    func testStartRcording() {
        let expect = expectation(description: "recording finished sucessfully")
        manager.startRecording { (data: Data, isRecording: Bool) in
            XCTAssertFalse(data.isEmpty)
            XCTAssertTrue(isRecording)
            expect.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(expect.expectedFulfillmentCount, 1)
    }

}
