import Foundation

public typealias ByteSender = ((Data) -> Void)

public protocol Client {

    /**
     Call this method to initialize a new audio stream.

     Note: You can immediately start sending audio data to the returned ByteSender.
      -Parameter entity: json request corresponding to the initial text request sent to initialize a conversation. see [Api Message Structure]https://developers.voysis.com/docs/message-structure.
      -Parameter onMessage: receives raw string responses from server.
      -Parameter onError: receives error responses from server.
      -Return: ByteSender method used to stream binary data
    */
    func setupAudioStream(entity: String, onMessage: @escaping ((String) -> Void), onError: @escaping ((VoysisError) -> Void)) -> ByteSender

    /**
     This method opens a websocket and posts a json string `entity` through it.

     Note: `setupAudioStream` internally calls this method.
     -Parameter entity: json string sent through websocket
     -Parameter onMessage: receives raw string responses from server.
     -Parameter onError: receives error responses from server.
    */
    func sendString(entity: String, onMessage: ((String) -> Void)?, onError: ((VoysisError) -> Void)?)

    ///Call this method to cancel the current request and disconnect from server.
    func cancelAudioStream()
}
