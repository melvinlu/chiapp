import Foundation
import Speech
import AVFoundation

protocol SpeechRecognitionService {
    func requestPermission() async -> Bool
    func transcribeAudio(from url: URL) async throws -> String
}

final class AppleSpeechRecognitionService: SpeechRecognitionService {
    private let speechRecognizer: SFSpeechRecognizer?
    
    init(locale: Locale = Locale(identifier: "zh-CN")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    continuation.resume(returning: true)
                case .denied, .restricted, .notDetermined:
                    continuation.resume(returning: false)
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func transcribeAudio(from url: URL) async throws -> String {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            
            speechRecognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result, result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    continuation.resume(returning: transcription)
                }
            }
        }
    }
}

// MARK: - Noop Implementation
final class NoopSpeechRecognitionService: SpeechRecognitionService {
    func requestPermission() async -> Bool {
        return true
    }
    
    func transcribeAudio(from url: URL) async throws -> String {
        return "Mock transcription"
    }
}

// MARK: - Errors
enum SpeechRecognitionError: Error, LocalizedError {
    case recognizerNotAvailable
    case permissionDenied
    case transcriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer not available"
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        }
    }
}