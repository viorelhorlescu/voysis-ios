import Foundation

public protocol FeedbackType: Codable {
}

public struct FeedbackRequest<T: FeedbackType>: Codable {
    public let entity: T
    public let requestID: String = "feedback"
    public let headers: Headers
    public let method = "PATCH"
    public let type = "request"
    public let restURI: String

    enum CodingKeys: String, CodingKey {
        case entity, headers, method
        case requestID = "requestId"
        case restURI = "restUri"
        case type
    }
}

public struct DurationEntity: FeedbackType, Codable {
    public var durations = Durations()
    public init(){
    }
}

public struct Durations: Codable {
    public var vad, complete: Int?
}
