public enum VoysisError: Error {
    case permissionNotGrantedError
    case duplicateProcessingRequest
    case serializationError(String)
    case requestEncodingError
    case internalServerError
    case networkError(String)
    case unauthorized
    case unknownError
    case tokenError

}
