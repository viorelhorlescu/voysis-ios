import Foundation

/**
 The Voysis.ServiceProvider is the sdk's is the primary object for making Voysis.Service instances.

 Note: In order for this class to work correctly the `<C: Context, E: Entities>` generic types
 must be implemented by concrete classes that are of the same type that the user expects returned from the server.
 See the sample application for an example of a correct implementation of `Context` and `Entities`
*/
public struct ServiceProvider<C: Context, E: Entities> {

    /**
     -Parameter config: containing url endpoint and refreshToken.
     -Return: new instance of Voysis.Service
    */
    public static func make(config: Config) -> Service {
        return make(config: config, recorder: AudioRecorderImpl())
    }

    /**
     -Parameter config: containing url endpoint and refreshToken.
     -Parameter recorder: AudioRecorder
     -Parameter callbackQueue: (Optional) DispatchQueue used for event, error callbacks. Defaults to DispatchQueue.main.
     -Return new instance of Voysis.Service
    */
    public static func make(config: Config, recorder: AudioRecorder, callbackQueue: DispatchQueue = DispatchQueue.main) -> Service {
        let client = VoysisWebSocketClient(request: URLRequest(url: config.url), dispatchQueue: callbackQueue)
        let tokenManager = TokenManager(refreshToken: config.refreshToken, dispatchQueue: callbackQueue)
        let feedbackManager = FeedbackManager(callbackQueue)
        return ServiceImpl<C, E>(client: client,
                recorder: recorder,
                feedbackManager: feedbackManager,
                tokenManager: tokenManager,
                userId: config.userId,
                dispatchQueue: callbackQueue)
    }
}
