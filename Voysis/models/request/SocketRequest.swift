import UIKit
import Foundation

struct SocketRequest<C: Context>: Codable {
    let entity: RequestEntity<C>?
    let requestID: String = "0"
    let headers: Headers
    let method = "POST"
    let type = "request"
    let restURI: String

    enum CodingKeys: String, CodingKey {
        case entity, headers, method
        case requestID = "requestId"
        case restURI = "restUri"
        case type
    }
}

public struct RequestEntity<C: Context>: Codable {
    public let audioQuery: AudioQuery? = AudioQuery()
    public let queryType: String? = "audio"
    public let locale: String? = "en-US"
    public let userId: String?
    public let context: C?
}

public struct AudioQuery: Codable {
    public let mimeType: String? = "audio/pcm"
}

public struct Headers: Codable {
    var accept: String? = "application/vnd.voysisquery.v1+json"
    var xVoysisIgnoreVad: Bool? = false
    var audioProfileId: String? = ""
    var authorization: String?
    var userAgent: String?

    public init(token: String?) {
        audioProfileId = getAudioProfileId()
        userAgent = getUserAgent()
        if let token = token {
            authorization = "Bearer \(token)"
        }

    }

    init(accept: String?, xVoysisIgnoreVad: Bool?, acceptLanguage: String?, authorization: String, audioProfileId: String?, userAgent: String?) {
        self.xVoysisIgnoreVad = xVoysisIgnoreVad
        self.audioProfileId = audioProfileId
        self.authorization = authorization
        self.userAgent = userAgent
        self.accept = accept
    }

    enum CodingKeys: String, CodingKey {
        case audioProfileId = "X-Voysis-Audio-Profile-Id"
        case xVoysisIgnoreVad = "X-Voysis-Ignore-Vad"
        case authorization = "Authorization"
        case userAgent = "User-Agent"
        case accept = "Accept"
    }
}

extension Headers {

    private func getUserAgent() -> String {
        let current = UIDevice.current
        let unknown = "unknown"
        let appBundle = Bundle.main
        let appIdentifier = appBundle.bundleIdentifier ?? unknown
        let appVersion = appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? unknown
        let libBundle = Bundle(for: VoysisWebSocketClient.self)
        let libIdentifier = libBundle.bundleIdentifier ?? unknown
        let libVersion = libBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? unknown
        return "(\(current.systemName) \(current.systemVersion); \(current.model)) \(appIdentifier)/\(appVersion) \(libIdentifier)/\(libVersion)"
    }

    public func getAudioProfileId() -> String {
        let defaults = UserDefaults.standard
        guard let id = defaults.string(forKey: "audioProfileId") else {
            let newId = UUID().uuidString
            defaults.set(newId, forKey: "audioProfileId")
            return newId
        }
        return id
    }
}
