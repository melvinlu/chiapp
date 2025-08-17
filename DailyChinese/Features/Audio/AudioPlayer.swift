import Foundation
import AVFoundation

protocol AudioPlayable {
    func play(url: URL) async
    func stop()
    var isPlaying: Bool { get }
}

final class AudioPlayer: NSObject, AudioPlayable, ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published private(set) var isPlaying: Bool = false
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetooth, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    func play(url: URL) async {
        await MainActor.run {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                isPlaying = true
            } catch {
                print("Failed to play audio: \(error)")
                isPlaying = false
            }
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "Unknown")")
        isPlaying = false
    }
}