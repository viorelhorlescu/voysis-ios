import Foundation

public protocol AudioRecorder {

    /**
     Parameter onDataResponse: called when audio buffer fills.
     */
    func start(onDataResponse: @escaping ((Data, Bool) -> Void))

    ///stop recording audio
    func stop()
}
