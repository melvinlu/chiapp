import Foundation
import Combine

@MainActor
final class SingleSentenceViewModel: ObservableObject {
    @Published var currentSentence: SentenceVM?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var allSentences: [SentenceVM] = []
    
    private let sentenceStore: SentenceStore
    private let audioPlayer: AudioPlayable
    private let tts: TTSService
    private var cancellables = Set<AnyCancellable>()
    private var viewedSentences: [SentenceVM] = []
    private var currentIndex = 0
    
    // Cached preview sentences to prevent flickering
    private var cachedNextPreview: SentenceVM?
    private var cachedPreviousPreview: SentenceVM?
    
    init(sentenceStore: SentenceStore, audioPlayer: AudioPlayable, tts: TTSService) {
        self.sentenceStore = sentenceStore
        self.audioPlayer = audioPlayer
        self.tts = tts
        
        Task {
            await loadAllSentences()
            await loadRandomSentence()
        }
    }
    
    func loadAllSentences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all sentences from all dates (history)
            let calendar = Calendar.current
            let today = Date()
            var allSentenceEntities: [SentenceEntity] = []
            
            // Load sentences from the last 30 days to build a good history
            for dayOffset in 0..<30 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    let sentences = try await sentenceStore.fetchAllSentences(for: date)
                    allSentenceEntities.append(contentsOf: sentences)
                }
            }
            
            // Convert to view models and remove duplicates
            let uniqueSentences = Dictionary(grouping: allSentenceEntities, by: \.id)
                .compactMapValues { $0.first }
                .values
                .map { SentenceVM(from: $0) }
                .sorted { $0.createdAt ?? Date.distantPast > $1.createdAt ?? Date.distantPast }
            
            allSentences = Array(uniqueSentences)
            updateCachedPreviews()
        } catch {
            errorMessage = "Failed to load sentences: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadRandomSentence() async {
        guard !allSentences.isEmpty else {
            await loadAllSentences()
            return
        }
        
        // Select a random sentence from the history
        if let randomSentence = allSentences.randomElement() {
            viewedSentences.append(randomSentence)
            currentIndex = viewedSentences.count - 1
            currentSentence = randomSentence
            updateCachedPreviews()
        }
    }
    
    func nextSentence() async {
        if currentIndex < viewedSentences.count - 1 {
            // Move forward in viewed history
            currentIndex += 1
            currentSentence = viewedSentences[currentIndex]
        } else {
            // Load new random sentence
            await loadRandomSentence()
        }
        updateCachedPreviews()
    }
    
    func previousSentence() async {
        if currentIndex > 0 {
            currentIndex -= 1
            currentSentence = viewedSentences[currentIndex]
            updateCachedPreviews()
        }
    }
    
    var canGoBack: Bool {
        currentIndex > 0
    }
    
    var canGoForward: Bool {
        currentIndex < viewedSentences.count - 1
    }
    
    var nextSentencePreview: SentenceVM? {
        return cachedNextPreview
    }
    
    var previousSentencePreview: SentenceVM? {
        return cachedPreviousPreview
    }
    
    private func updateCachedPreviews() {
        // Update previous preview
        cachedPreviousPreview = if currentIndex > 0 {
            viewedSentences[currentIndex - 1]
        } else {
            nil
        }
        
        // Update next preview
        cachedNextPreview = if currentIndex < viewedSentences.count - 1 {
            viewedSentences[currentIndex + 1]
        } else if !allSentences.isEmpty {
            // Generate a stable random next sentence
            allSentences.randomElement()
        } else {
            nil
        }
    }
    
    func playAudio() async {
        guard let sentence = currentSentence else { return }
        
        if let audioURL = sentence.audioURL {
            // Play from URL if available
            await audioPlayer.play(url: audioURL)
        } else {
            // Use TTS service
            await tts.speak(sentence.hanzi, language: "zh-CN")
        }
    }
    
}

extension SentenceVM {
    init(id: String, hanzi: String, pinyin: String, english: String, packDate: Date, indexInPack: Int, audioURL: URL?, isLearned: Bool, isFavorite: Bool, createdAt: Date?, batchId: String?) {
        self.id = id
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.english = english
        self.packDate = packDate
        self.indexInPack = indexInPack
        self.audioURL = audioURL
        self.isLearned = isLearned
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.batchId = batchId
    }
}