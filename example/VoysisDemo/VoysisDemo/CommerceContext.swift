import Voysis
import Foundation

public struct CommerceContext: Context {
    public var attributes: [String: [String]]?
    public var keywords: [String]?
    public var sortBy: String?
    public var price: Price?

    public init() {
    }
}

public struct Attribute: Codable {
    public let value: [String]?
    public let key: String
}

public struct Price: Codable {
    public let type: String?
    public var value: String?
    public var from: String?
    public var to: String?
}
