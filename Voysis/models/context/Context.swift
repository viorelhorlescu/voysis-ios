public protocol Context: Codable {
}

public protocol Entities: Codable {
}

internal class EmptyContext: Context {
    //called when making socket request that does not contain context, eg token, feedback
}
