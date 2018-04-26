internal struct Response<T: ApiResponse>: Codable {
    let entity: T?
    let responseMessage: String?
    let requestId: String?
    let responseCode: Int?
    let notificationType: String?
    var type: String
}

public struct Audio: Codable {
    let href: String?
}

public struct Reply: Codable {
    public let text: String?
}

public struct Links: Codable {
    let linksSelf, audio: Audio?

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case audio
    }
}

public protocol ApiResponse: Codable {
}

public struct EmptyResponse: ApiResponse {
    //called when decoding external server response before response type is known
}

public struct QueryResponse: ApiResponse, Codable {
    public let id, locale, conversationId, queryType: String?
    public let audioQuery: AudioQuery?
    public let requestId: String?
    public let links: Links?
}

public struct StreamResponse<C: Context, E: Entities>: ApiResponse, Codable {
    public let id, locale, conversationId, queryType: String?
    public let audioQuery: AudioQuery?
    public let textQuery: Reply?
    public let intent: String?
    public let reply: Reply?
    public let entities: E?
    public let context: C?
    public let links: Links?
}

public struct Token: ApiResponse, Codable {
    let expiresAt: String
    let token: String
}
