import Foundation

internal class FeedbackManager {

    var dispatchQueue: DispatchQueue!
    var feedbackErrorHandler: ErrorHandler!
    var feedbackHandler: FeedbackHandler!

    init(_ dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }

    func onMessage(data: String) {
        do {
            let response = try Converter.decodeResponse(Response<EmptyResponse>.self, data)
            switch response.responseCode! {
            case 200...299:
                dispatchQueue.async {
                    self.feedbackHandler?(response.responseCode!)
                }
            default:
                onError(VoysisError.networkError(response.responseMessage!))
            }
        } catch {
            if let error = error as? VoysisError {
                onError(error)
            }
        }
    }

    func onError(_ error: VoysisError) {
        dispatchQueue.async {
            self.feedbackErrorHandler?(error)
        }
    }

}