import AVFoundation

internal class ServiceImpl<C: Context, E: Entities>: Service {
    private let session = AVAudioSession.sharedInstance()
    private let dispatchQueue: DispatchQueue
    private let tokenManager: TokenManager
    private let audioQueue: OperationQueue
    private let converter = Converter()
    private let recorder: AudioRecorder
    private let client: Client
    private let userId: String?

    private var errorHandler: ErrorHandler!
    private var eventHandler: EventHandler!

    private var byteSender: ByteSender?
    private var maxBytes = 320000

    public var state = State.idle

    init(client: Client, recorder: AudioRecorder, tokenManager: TokenManager, userId: String?, dispatchQueue: DispatchQueue) {
        self.client = client
        self.recorder = recorder
        self.tokenManager = tokenManager
        self.userId = userId
        self.dispatchQueue = dispatchQueue
        audioQueue = OperationQueue()
        audioQueue.name = "VoysisAudioRequests"
        audioQueue.maxConcurrentOperationCount = 1
        audioQueue.isSuspended = true
    }

    public func startAudioQuery(context: Context?, eventHandler: @escaping  EventHandler, errorHandler: @escaping ErrorHandler) {
        if state != .idle {
            handleError(.duplicateProcessingRequest)
            return
        }
        self.errorHandler = errorHandler
        self.eventHandler = eventHandler
        session.requestRecordPermission { granted in
            guard granted else {
                self.handleError(.permissionNotGrantedError)
                return
            }
            self.performAudioQuery(context: context)
        }
    }

    public func refreshSessionToken(tokenHandler: @escaping TokenHandler, errorHandler: @escaping ErrorHandler) {
        tokenManager.tokenHandler = tokenHandler
        tokenManager.tokenErrorHandler = errorHandler
        do {
            let entity = try Converter.encodeRequest(context: nil as EmptyContext?, token: tokenManager.refreshToken, path: "/tokens")
            client.sendString(entity: entity!, onMessage: tokenManager.onTokenMessage, onError: tokenManager.onError)
        } catch {
            if let error = error as? VoysisError {
                handleError(error)
            }
        }
    }

    public func finish() {
        stop(Data([4]))
    }

    public func cancel() {
        stop()
        client.cancelAudioStream()
        state = .idle
    }

    private func performAudioQuery(context: Context?) {
        state = .busy
        startRecording()
        if tokenManager.tokenIsValid() {
            startAudioQuery(context: context)
        } else {
            refreshSessionToken(tokenHandler: { _ in self.startAudioQuery(context: context) }, errorHandler: errorHandler)
        }
    }

    private func startAudioQuery(context: Context?) {
        do {
            if let entity = try Converter.encodeRequest(context: context as? C, userId: userId, token: tokenManager.token!.token, path: "/queries") {
                byteSender = client.setupAudioStream(entity: entity, onMessage: self.onMessage, onError: self.onError)
                audioQueue.isSuspended = false
            }
        } catch {
            handleError(.requestEncodingError)
        }
    }

    private func startRecording() {
        audioQueue.cancelAllOperations()
        audioQueue.isSuspended = true
        byteSender = nil
        var bytesRead = 0
        recorder.start {
            self.audioCallback(data: $0, isRecording: $1, bytesRead: &bytesRead)
        }
        handleEvent(Event(response: nil, type: .recordingStarted))
    }

    private func audioCallback(data: Data, isRecording: Bool, bytesRead: inout Int) {
        if !isRecording {
            handleEvent(Event(response: nil, type: .recordingFinished))
        }
        guard !data.isEmpty else {
            return
        }
        queueAudio(data)
        bytesRead += data.count
        if bytesRead >= maxBytes {
            finish()
        }
    }

    private func stop(_ data: Data? = nil) {
        recorder.stop()
        queueAudio(data)
    }

    private func queueAudio(_ data: Data?) {
        audioQueue.addOperation {
            if data != nil {
                self.byteSender?(data!)
            }
        }
    }

    private func handleError(_ error: VoysisError) {
        dispatchQueue.async {
            self.errorHandler?(error)
        }
    }

    private func handleEvent(_ event: Event) {
        dispatchQueue.async {
            self.eventHandler?(event)
        }
    }

    private func onError(exception: VoysisError) {
        cancel()
        handleError(exception)
    }

    private func onMessage(data: String) {
        do {
            let event = try Converter.decodeResponse(json: data, context: C.self, entity: E.self)
            switch event.type {
            case .recordingFinished:
                stop()
            case .audioQueryCompleted:
                state = .idle
                handleEvent(event)
            default:
                handleEvent(event)
            }
        } catch {
            cancel()
            if let error = error as? VoysisError {
                self.errorHandler?(error)
            }
        }
    }

}
