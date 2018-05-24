public typealias ErrorHandler = (VoysisError) -> Void
public typealias EventHandler = (Event) -> Void
public typealias TokenHandler = (Token) -> Void
public typealias FeedbackHandler = (Int) -> Void

public enum State {
    case idle
    case busy
}

public protocol Service {

    /**
     when `startAudioQuery` has been called, state will turn to `State.busy`.
     when `EventType.audioQueryCompleted is returned from the EventHandler.Event the state will return to `State.idle`
     if an error occurs the state will also return to `State.idle`

     - Returns: state of current audio stream request
     */
    var state: State { get }

    /**
     This method kicks off an audio query. Under the hood this method invokes `Voysis.Client.setupAudioStream` which
     connects to the underlining websocket, initiates an audio query request and begins streaming audio from the
     microphone through the open connection

     Note: the user will be prompted to accept audio permissions if they have not done so already.

     for more information on the websocket api calls see https://developers.voysis.com/docs

     - Parameter context:(optional) the context object from the previous response. Nil if is first request.
     - Parameter eventHandler: called whenever event returns from socket.
           - see `Event.EventType` for all possible return values
           - this method will call back to the same thread that called `startAudioQuery`
     - Parameter errorHandler: called if error occurs
           - see `VoysisError` for all possible error types
           - this method will call back to the same thread that called `startAudioQuery`
     */
    func startAudioQuery(context: Context?, eventHandler: @escaping EventHandler, errorHandler: @escaping ErrorHandler)

    ///Call to manually stop recording audio and process request
    func finish()

    ///Call to cancel request.
    func cancel()

    /**
      Call this method to manually refresh the session token.
      Note: The sdk automatically handles checking/refreshing and storing the session token.
      This method is called internally by `startAudioQuery`.
      Calling this method will preemptively refresh the session token for users who want to manage token refresh themselves.
     - Parameter tokenHandler: called whenever token returns from socket.
     - Parameter errorHandler: called if error occurs
    */
    func refreshSessionToken(tokenHandler: @escaping TokenHandler, errorHandler: @escaping ErrorHandler)

    func sendFeedback(queryId: String, feedback: FeedbackData, feedbackHandler: @escaping FeedbackHandler, errorHandler: @escaping ErrorHandler)

}
