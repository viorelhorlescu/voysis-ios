import XCTest
@testable import Voysis

class VoysisTests: XCTestCase {
    class TestContext: Context {
    }

    class TestEntities: Entities {
    }

    let token = "{\"type\":\"response\",\"entity\":{\"token\":\"1\",\"expiresAt\":\"2018-04-17T14:14:06.701Z\"},\"requestId\":\"0\",\"responseCode\":200,\"responseMessage\":\"OK\"}"

    private var voysis: ServiceImpl<TestContext, TestEntities>!
    private var audioRecordManager: AudioRecordManagerMock!
    private var client: ClientMock!
    private var context: Context?
    private var resreshToken = "token"

    override func setUp() {
        super.setUp()
        client = ClientMock()
        audioRecordManager = AudioRecordManagerMock()
        let tokenManager = TokenManager(refreshToken: resreshToken, dispatchQueue: DispatchQueue.main)
        voysis = ServiceImpl(client: client, recorder: audioRecordManager, tokenManager: tokenManager, userId: "", dispatchQueue: DispatchQueue.main)

        //closure cannot be null but is not required for most tests.
        client.dataCallback = { ( data: Data) in
        }
    }

    override func tearDown() {
        super.tearDown()
        voysis = nil
        audioRecordManager = nil
        client = nil

    }

    func testCreateAndFinishRequestWithVad() {
        let vadReceived = expectation(description: "vad received")
        client.stringEvent = token
        client.setupStreamEvent = "{\"type\":\"notification\",\"notificationType\":\"vad_stop\"}"
        audioRecordManager.onDataResponse = { (data: Data, isRecording: Bool) in
        }
        let voysisEvent = { (event: Event) in
            if (event.type == EventType.recordingFinished) {
                vadReceived.fulfill()
            }
        }
        voysis.startAudioQuery(context: context, eventHandler: voysisEvent, errorHandler: { (_: VoysisError) in })
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCreateAndManualFinishRequest() {
        let endData = expectation(description: "4 bytes sent at end")
        client.dataCallback = { ( data: Data) in
            XCTAssertTrue(data.count == 1)
            endData.fulfill()
        }
        let voysisEvent = { (event: Event) in
            //ignore
        }
        client.stringEvent = token
        voysis.startAudioQuery(context: context, eventHandler: voysisEvent, errorHandler: { (_: VoysisError) in })
        voysis.finish()
        waitForExpectations(timeout: 5, handler: nil)

    }

    func testErrorResposne() {
        let errorReceived = expectation(description: "error received")
        client.error = VoysisError.unknownError
        let errorHandler = { (_: VoysisError) in
            errorReceived.fulfill()
        }
        voysis.startAudioQuery(context: context, eventHandler: { (_: Event) in }, errorHandler: errorHandler)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testStateChanges() {
        XCTAssertEqual(voysis.state, State.idle)
        client.stringEvent = token
        client.setupStreamEvent = "{\"type\":\"notification\",\"notificationType\":\"vad_stop\"}"
        audioRecordManager.onDataResponse = { (data: Data, isRecording: Bool) in
        }
        let completed = expectation(description: "completed")
        let voysisEvent = { (event: Event) in
            if (event.type == EventType.recordingFinished) {
                completed.fulfill()
            }
        }
        voysis.startAudioQuery(context: context, eventHandler: voysisEvent, errorHandler: { (_: VoysisError) in })
        XCTAssertEqual(voysis.state, State.busy)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testMaxByteLimitOnRequest() {
        let completed = expectation(description: "max bytes exceeded. byte(4) sent at end ")
        audioRecordManager.data = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 320001)
        client.dataCallback = { ( data: Data) in
            if (data.count == 1) {
                completed.fulfill()
            }
        }
        client.stringEvent = token
        voysis.startAudioQuery(context: context, eventHandler: { (_: Event) in }, errorHandler: { (_: VoysisError) in })
        waitForExpectations(timeout: 5, handler: nil)
    }
}
