import SwiftUI
import SwiftData

struct DIContainer {
    let sentenceStore: SentenceStore
    let audioPlayer: AudioPlayable
    let tts: TTSService
    let ai: AIService
    let recorder: RecorderService
    let speechRecognition: SpeechRecognitionService
    let pronunciationGrading: PronunciationGradingService
}

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.preview
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

extension DIContainer {
    static var preview: DIContainer {
        DIContainer(
            sentenceStore: InMemoryRepository(sentences: InMemoryRepository.mockSentences()),
            audioPlayer: AudioPlayer(),
            tts: HybridTTSService(),
            ai: NoopAIService(),
            recorder: NoopRecorderService(),
            speechRecognition: NoopSpeechRecognitionService(),
            pronunciationGrading: NoopPronunciationGradingService()
        )
    }
    
    static var empty: DIContainer {
        DIContainer(
            sentenceStore: InMemoryRepository(sentences: []),
            audioPlayer: AudioPlayer(),
            tts: HybridTTSService(),
            ai: NoopAIService(),
            recorder: NoopRecorderService(),
            speechRecognition: NoopSpeechRecognitionService(),
            pronunciationGrading: NoopPronunciationGradingService()
        )
    }
    
    static func production(modelContext: ModelContext) -> DIContainer {
        let localRepo = LocalRepository(modelContext: modelContext)
        let networkRepo = NetworkRepository(fallbackRepository: localRepo)
        
        return DIContainer(
            sentenceStore: networkRepo,
            audioPlayer: AudioPlayer(),
            tts: HybridTTSService(),
            ai: NoopAIService(),
            recorder: AudioRecorderService(),
            speechRecognition: AppleSpeechRecognitionService(),
            pronunciationGrading: OpenAIPronunciationGradingService()
        )
    }
}