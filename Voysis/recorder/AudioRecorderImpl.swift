import Foundation
import AudioToolbox
import AVFoundation

class AudioRecorderImpl: AudioRecorder {

    internal var onDataResponse: ((Data, Bool) -> Void)?
    private var format = AudioStreamBasicDescription()
    private var queue: AudioQueueRef?
    private var player: AudioPlayer
    private var inProgress = false
    private var bufferRefs = [UnsafeMutablePointer<AudioQueueBufferRef?>]()

    public convenience init() {
        self.init(player: AudioPlayerImpl())
    }

    public init(player: AudioPlayer) {
        self.player = player
        setFormatDescription()
    }

    public func start(onDataResponse: @escaping ((Data, Bool) -> Void)) {
        guard !inProgress else {
            return
        }
        self.onDataResponse = onDataResponse
        setupAudioQueue()
        inProgress = true
        player.playStartAudio { [weak self] in
            guard let this = self else {
                return
            }
            guard let queue = this.queue else {
                return
            }
            AudioQueueStart(queue, nil)
        }
    }

    public func stop() {
        guard inProgress else {
            return
        }

        guard let queue = queue else {
            return
        }
        inProgress = false
        AudioQueueFlush(queue)
        AudioQueueStop(queue, true)
        AudioQueueDispose(queue, true)
        clearBuffers()
        player.playStopAudio()
    }

    private func clearBuffers() {
        for buffer in bufferRefs {
            buffer.deallocate()
        }
        bufferRefs.removeAll()
    }

    private func setFormatDescription() {
        var formatFlags = AudioFormatFlags()
        formatFlags |= kLinearPCMFormatFlagIsSignedInteger
        formatFlags |= kLinearPCMFormatFlagIsPacked
        format = AudioStreamBasicDescription(
                mSampleRate: 16000.0,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: formatFlags,
                mBytesPerPacket: UInt32(1 * MemoryLayout<Int16>.stride),
                mFramesPerPacket: 1,
                mBytesPerFrame: UInt32(1 * MemoryLayout<Int16>.stride),
                mChannelsPerFrame: 1,
                mBitsPerChannel: 16,
                mReserved: 0
        )
    }

    private let callback: AudioQueueInputCallback = { data, queue, bufferRef, _, _, _ in
        guard let data = data else {
            return
        }
        let audioRecorder = Unmanaged<AudioRecorderImpl>.fromOpaque(data).takeUnretainedValue()

        let buffer = bufferRef.pointee
        autoreleasepool {
            let data = Data(bytes: buffer.mAudioData, count: Int(buffer.mAudioDataByteSize))
            audioRecorder.onDataResponse?(data, audioRecorder.inProgress)
        }

        // return early if recording is stopped
        guard audioRecorder.inProgress else {
            return
        }

        if let queue = audioRecorder.queue {
            AudioQueueEnqueueBuffer(queue, bufferRef, 0, nil)
        }
    }

    private func setupAudioQueue() {
        let pointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        AudioQueueNewInput(&format, callback, pointer, nil, nil, 0, &queue)

        guard let queue = queue else {
            return
        }

        // update audio format
        var formatSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.stride)
        AudioQueueGetProperty(queue, kAudioQueueProperty_StreamDescription, &format, &formatSize)

        // allocate and enqueue buffers
        let numBuffers = 2
        let bufferSize = deriveBufferSize(seconds: 0.5)
        for _ in 0..<numBuffers {
            let bufferRef = UnsafeMutablePointer<AudioQueueBufferRef?>.allocate(capacity: 1)
            bufferRefs.append(bufferRef)
            AudioQueueAllocateBuffer(queue, bufferSize, bufferRef)
            if let buffer = bufferRef.pointee {
                AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
            }
        }
    }

    private func deriveBufferSize(seconds: Float64) -> UInt32 {
        guard let queue = queue else {
            return 0
        }
        let maxBufferSize = UInt32(0x50000)
        var maxPacketSize = format.mBytesPerPacket
        if maxPacketSize == 0 {
            var maxVBRPacketSize = UInt32(MemoryLayout<UInt32>.stride)
            AudioQueueGetProperty(
                    queue,
                    kAudioQueueProperty_MaximumOutputPacketSize,
                    &maxPacketSize,
                    &maxVBRPacketSize
            )
        }

        let numBytesForTime = UInt32(format.mSampleRate * Float64(maxPacketSize) * seconds)
        let bufferSize = (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize)
        return bufferSize
    }

}
