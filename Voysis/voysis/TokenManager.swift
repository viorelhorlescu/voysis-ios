import Foundation

internal class TokenManager {

    private let dispatchQueue: DispatchQueue
    var tokenErrorHandler: ErrorHandler!
    var tokenHandler: TokenHandler!
    let refreshToken: String
    var token: Token?

    init(refreshToken: String, dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
        self.refreshToken = refreshToken
    }

    func onTokenMessage(data: String) {
        do {
            let tokenResponse = try Converter.decodeResponse(Response<Token>.self, data)
            let responseCode = tokenResponse.responseCode
            if responseCode == 403 || responseCode == 401 {
                onError(VoysisError.unauthorized)
            } else {
                let entity = tokenResponse.entity
                self.token = entity
                dispatchQueue.async {
                    self.tokenHandler?(entity!)
                }
            }
        } catch {
            if let error = error as? VoysisError {
                onError(error)
            }
        }
    }

    func onError(_ error: VoysisError) {
        dispatchQueue.async {
            self.tokenErrorHandler?(error)
        }
    }

    func tokenIsValid() -> Bool {
        return token != nil && tokenDate() > Date().addingTimeInterval(30)
    }

    private func tokenDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: token!.expiresAt)!
    }

}
