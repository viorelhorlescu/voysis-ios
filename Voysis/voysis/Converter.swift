import Foundation

/*
 Struct manages converting requests/responses into their correct object types
*/
internal struct Converter {

    static let serverError = "internal_server_error"
    static let queryComplete = "query_complete"
    static let notification = "notification"
    static let response = "response"
    static let vadStop = "vad_stop"

    static func encodeRequest<C: Context>(context: C?, userId: String? = nil, token: String, path: String) throws -> String? {
        let request = SocketRequest(entity: RequestEntity(userId: userId, context: context), headers: Headers(token: token), restURI: path)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(request),
           let json = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/") {
            return json
        }
        throw VoysisError.requestEncodingError
    }

    static func decodeResponse<C: Context, E: Entities>(json: String, context: C.Type, entity: E.Type) throws -> Event {
        do {
            let internalResponse = try Converter.decodeResponse(Response<EmptyResponse>.self, json)
            switch internalResponse.type {
            case response:
                let queryResponse = try Converter.decodeResponse(Response<QueryResponse>.self, json)
                return Event(response: queryResponse.entity, type: .audioQueryCreated)
            case notification:
                let type = internalResponse.notificationType!
                if type == vadStop {
                    return Event(response: nil, type: .recordingFinished)
                } else if type == queryComplete {
                    let streamResponse = try Converter.decodeResponse(Response<StreamResponse<C, E>>.self, json)
                    return Event(response: streamResponse.entity, type: .audioQueryCompleted)
                } else if type == serverError {
                    throw VoysisError.internalServerError
                } else {
                    throw VoysisError.unknownError
                }
            default:
                throw VoysisError.serializationError(json)
            }
        } catch {
            throw VoysisError.serializationError(json)
        }
    }

    static func decodeResponse<T: Codable>(_ type: T.Type = T.self, _ data: String) throws -> T {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(type.self, from: data.data(using: .utf8)!)
        } catch {
            throw error
        }
    }

}
