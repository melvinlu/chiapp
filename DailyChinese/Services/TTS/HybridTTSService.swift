import Foundation
import AVFoundation

final class HybridTTSService: NSObject, TTSService, ObservableObject {
    @Published private(set) var isSpeaking: Bool = false
    
    private let openAITTS: OpenAITTSService
    private let systemTTS: AVSpeechTTSService
    
    override init() {
        self.openAITTS = OpenAITTSService()
        self.systemTTS = AVSpeechTTSService()
        super.init()
        
        // Observe changes from both services
        openAITTS.$isSpeaking
            .assign(to: &$isSpeaking)
    }
    
    func speak(_ text: String, language: String) async {
        // Try OpenAI TTS first for better quality
        print("🎙️ Attempting OpenAI TTS...")
        
        do {
            await openAITTS.speak(text, language: language)
            print("✅ OpenAI TTS succeeded")
        } catch {
            print("❌ OpenAI TTS failed: \(error)")
            print("🎙️ Falling back to system TTS...")
            
            // Fallback to system TTS
            await systemTTS.speak(text, language: language)
        }
    }
    
    func stop() {
        openAITTS.stop()
        systemTTS.stop()
        isSpeaking = false
    }
}