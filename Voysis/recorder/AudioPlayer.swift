import UIKit
import AVFoundation
import MediaPlayer

public protocol AudioPlayer {
    func playStartAudio(onCompletionCallback: (() -> Void)?)
    func playStopAudio()
}

public class AudioPlayerImpl: NSObject, AudioPlayer, AVAudioPlayerDelegate {

    private var onComplete: (() -> Void)?
    private var player: AVAudioPlayer!
    private var startAudioPath: URL?
    private var stopAudioPath: URL?

    public convenience override init() {
        self.init(startAudioPath: Bundle(for: type(of: self)).url(forResource: "voysis_on", withExtension: "mp3")!,
                stopAudioPath: Bundle(for: type(of: self)).url(forResource: "voysis_off", withExtension: "mp3")!)
    }

    public init(startAudioPath: URL?, stopAudioPath: URL?) {
        self.startAudioPath = startAudioPath
        self.stopAudioPath = stopAudioPath
    }

    public func playStartAudio(onCompletionCallback: (() -> Void)?) {
        play(path: startAudioPath, onComplete: onCompletionCallback)
    }

    public func playStopAudio() {
        play(path: stopAudioPath, onComplete: nil)
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onComplete?()
    }

    private func play(path: URL?, onComplete: (() -> Void)?) {
        if (path == nil) {
            onComplete?()
        } else {
            playFile(path: path!, onComplete: onComplete)
        }
    }

    private func playFile(path: URL, onComplete: (() -> Void)?) {
        self.onComplete = onComplete
        player?.delegate = nil
        player?.stop()
        guard let instance = try? AVAudioPlayer(contentsOf: path) else {
            return
        }
        player = instance
        player.prepareToPlay()
        player.delegate = self
        player.play()
    }

    private func stop() {
        self.player?.stop()
    }

    deinit {
        self.player?.delegate = nil
    }

}
