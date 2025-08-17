import Foundation
import AVFoundation

protocol TTSService {
    func speak(_ text: String, language: String) async
    func stop()
    var isSpeaking: Bool { get }
}

final class AVSpeechTTSService: NSObject, TTSService, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var isSpeaking: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetooth, .allowAirPlay, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session for TTS: \(error)")
        }
    }
    
    func speak(_ text: String, language: String) async {
        await MainActor.run {
            stop()
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            utterance.preUtteranceDelay = 0.1
            utterance.postUtteranceDelay = 0.1
            
            isSpeaking = true
            synthesizer.speak(utterance)
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension AVSpeechTTSService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}