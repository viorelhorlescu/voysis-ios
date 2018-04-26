@testable import Voysis
import Foundation

//Mock client class. if the user sets voysisEvent or error, it will get called when setupAudioStream is called.
class ClientMock: Client {
    var dataCallback: ((Data) -> Void)?
    var setupStreamEvent: String?
    var stringEvent: String?
    var error: VoysisError?

    func setupAudioStream(entity: String, onMessage: @escaping ((String) -> Void), onError: @escaping ((VoysisError) -> Void)) -> ((Data) -> Void) {
        if (setupStreamEvent != nil) {
            onMessage(setupStreamEvent!)
        } else if (error != nil) {
            onError(error!)
        }
        return dataCallback!
    }

    func sendString(entity: String, onMessage: ((String) -> Void)?, onError: ((VoysisError) -> Void)?) {
        if (stringEvent != nil) {
            onMessage?(stringEvent!)
        } else if (error != nil) {
            onError?(error!)
        }
    }

    func cancelAudioStream() {
    }
}
