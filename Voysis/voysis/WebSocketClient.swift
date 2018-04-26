import Starscream

/**
 Websocket implementation of Client interface. This class uses the Starscream.framework websocket class and delegate
 to connect to a webSocket and facilitate the streaming of text and binary data.

 All operations are queued within an OperationQueue, except for the `socket.connect()` call. Once a connection is made the
 operation queue `isSuspended` is set to false and all queued data is sent through the websocket and newly arriving packets
 are streamed.

 Note: subsequent calls will use the same open webSocket until the websocket times out due to inactivity or receives and error.

 The websocket will also be manually if the user calls `cancelAudioStream()`
*/

internal class VoysisWebSocketClient: Client, WebSocketDelegate {

    private let queue: OperationQueue
    private let socket: WebSocket

    private var onMessage: ((String) -> Void)?
    private var onError: ((VoysisError) -> Void)?

    init(request: URLRequest, dispatchQueue: DispatchQueue) {
        socket = WebSocket(request: request)
        socket.callbackQueue = dispatchQueue
        queue = OperationQueue()
        queue.name = "VoysisWebSocketRequests"
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true
    }

    func setupAudioStream(entity: String, onMessage: @escaping ((String) -> Void), onError: @escaping ((VoysisError) -> Void)) -> ((Data) -> Void) {
        sendString(entity: entity, onMessage: onMessage, onError: onError)
        return { [weak self] (data: Data) in
            guard let this = self else {
                return
            }
            this.send(data: data)
        }
    }

    func sendString(entity: String, onMessage: ((String) -> Void)?, onError: ((VoysisError) -> Void)?) {
        self.onMessage = onMessage
        self.onError = onError
        send(string: entity)
    }

    func cancelAudioStream() {
        queue.addOperation {
            self.queue.cancelAllOperations()
            self.queue.isSuspended = true
            self.socket.disconnect(forceTimeout: 0)
        }
    }

    private func send(data: Data) {
        queue.addOperation {
            self.socket.write(data: data)
        }
    }

    private func send(string: String) {
        if !socket.isConnected {
            connect()
        }
        queue.addOperation {
            self.socket.write(string: string)
        }
    }

    private func connect() {
        queue.cancelAllOperations()
        socket.delegate = self
        socket.connect()
    }

    internal func websocketDidConnect(socket: WebSocketClient) {
        queue.isSuspended = false
    }

    internal func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        socket.disconnect()
        queue.isSuspended = true
        if let error = error as? WSError {
            if error.code != 1001 {
                onError?(VoysisError.networkError(error.type.localizedDescription))
            }
        }
    }

    internal func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        onMessage?(text)
    }

    internal func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    }

}
