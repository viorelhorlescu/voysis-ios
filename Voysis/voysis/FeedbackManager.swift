import Foundation

internal class FeedbackManager {

    private let dispatchQueue: DispatchQueue
    var feedbackErrorHandler: ErrorHandler!
    var feedbackHandler: FeedbackHandler!
    var feedbackPath: String?

    init(_ dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }

    func onMessage(data: String) {
        do {
            let response = try Converter.decodeResponse(Response<EmptyResponse>.self, data)
            switch response.responseCode! {
            case 200...299:
                dispatchQueue.async {
                    self.feedbackHandler?(true)
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

    func hasPath() -> Bool {
        return feedbackPath != nil
    }

}