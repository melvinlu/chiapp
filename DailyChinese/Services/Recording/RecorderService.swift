import Foundation
import AVFoundation

protocol RecorderService {
    var isRecording: Bool { get }
    func startRecording() async throws
    func stopRecording() async -> URL?
}

final class AudioRecorderService: NSObject, RecorderService, ObservableObject {
    @Published private(set) var isRecording: Bool = false
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session for recording: \(error)")
        }
    }
    
    func startRecording() async throws {
        await stopRecording()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            await MainActor.run {
                isRecording = audioRecorder?.record() ?? false
                recordingURL = audioURL
            }
        } catch {
            print("Failed to start recording: \(error)")
            throw RecordingError.failedToStart
        }
    }
    
    @discardableResult
    func stopRecording() async -> URL? {
        await MainActor.run {
            audioRecorder?.stop()
            isRecording = false
            
            let url = recordingURL
            recordingURL = nil
            return url
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
        if let error = error {
            print("Audio recorder encode error: \(error)")
        }
    }
}

// MARK: - Noop Implementation
final class NoopRecorderService: RecorderService {
    var isRecording: Bool = false
    
    func startRecording() async throws {
        // No-op for previews/testing
    }
    
    func stopRecording() async -> URL? {
        return nil
    }
}

// MARK: - Errors
enum RecordingError: Error, LocalizedError {
    case failedToStart
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Failed to start recording"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}