import Foundation
import AVFoundation

final class OpenAITTSService: NSObject, TTSService, ObservableObject {
    @Published private(set) var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    private let urlSession: URLSession
    
    override init() {
        self.urlSession = URLSession.shared
        super.init()
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
            print("Failed to configure audio session for OpenAI TTS: \(error)")
        }
    }
    
    func speak(_ text: String, language: String) async {
        await MainActor.run {
            isSpeaking = true
        }
        
        do {
            // Get audio data from OpenAI TTS API
            let audioData = try await fetchTTSAudio(text: text)
            
            await MainActor.run {
                do {
                    // Play the audio
                    audioPlayer = try AVAudioPlayer(data: audioData)
                    audioPlayer?.delegate = self
                    audioPlayer?.play()
                } catch {
                    print("Failed to play OpenAI TTS audio: \(error)")
                    isSpeaking = false
                }
            }
        } catch {
            print("Failed to generate OpenAI TTS audio: \(error)")
            await MainActor.run {
                isSpeaking = false
            }
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }
    
    private func fetchTTSAudio(text: String) async throws -> Data {
        guard let apiKey = getOpenAIAPIKey() else {
            throw TTSError.noAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        
        let requestBody = OpenAITTSRequest(
            model: "tts-1",
            input: text,
            voice: "alloy", // Male-sounding voice
            response_format: "mp3",
            speed: 1.0
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestData = try JSONEncoder().encode(requestBody)
        request.httpBody = requestData
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.httpError
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("OpenAI TTS API Error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw TTSError.httpError
        }
        
        return data
    }
    
    private func getOpenAIAPIKey() -> String? {
        return AppConfig.shared.openAIAPIKey
    }
}

// MARK: - AVAudioPlayerDelegate
extension OpenAITTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.audioPlayer = nil
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.audioPlayer = nil
        }
        if let error = error {
            print("Audio player decode error: \(error)")
        }
    }
}

// MARK: - Data Types
struct OpenAITTSRequest: Codable {
    let model: String
    let input: String
    let voice: String
    let response_format: String
    let speed: Double
}

enum TTSError: Error, LocalizedError {
    case noAPIKey
    case httpError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .httpError:
            return "HTTP request failed"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}