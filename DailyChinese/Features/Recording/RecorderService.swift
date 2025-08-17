import Foundation
import AVFoundation

protocol RecorderService {
    func startRecording() throws
    func stopRecording() async throws -> URL
    var isRecording: Bool { get }
}

final class NoopRecorderService: RecorderService {
    private(set) var isRecording: Bool = false
    
    func startRecording() throws {
        isRecording = true
        print("Recording started (no-op)")
    }
    
    func stopRecording() async throws -> URL {
        isRecording = false
        print("Recording stopped (no-op)")
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("noop.m4a")
    }
}

final class AVRecorderService: NSObject, RecorderService, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    @Published private(set) var isRecording: Bool = false
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session for recording: \(error)")
        }
    }
    
    func startRecording() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).m4a"
        let audioFilename = documentsPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
        isRecording = true
    }
    
    func stopRecording() async throws -> URL {
        guard let recorder = audioRecorder else {
            throw RecordingError.noActiveRecording
        }
        
        recorder.stop()
        isRecording = false
        
        let url = recorder.url
        audioRecorder = nil
        return url
    }
}

extension AVRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        if !flag {
            print("Recording failed")
        }
    }
}

enum RecordingError: LocalizedError {
    case noActiveRecording
    
    var errorDescription: String? {
        switch self {
        case .noActiveRecording:
            return "No active recording session"
        }
    }
}