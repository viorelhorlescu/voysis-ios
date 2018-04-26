import Foundation

public struct Config {
    public let refreshToken: String
    public let userId: String?
    public let url: URL

    public init(url: URL, refreshToken: String, userId: String? = nil) {
        self.refreshToken = refreshToken
        self.userId = userId
        self.url = url
    }

    public init(url: URL) {
        self.init(url: url, refreshToken: "")
    }
}
