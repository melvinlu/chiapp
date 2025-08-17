import Foundation
import SwiftUI
import Combine

@MainActor
final class SentencesViewModel: ObservableObject {
    @Published var items: [SentenceVM] = []
    @Published var expandedID: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentlyPlayingID: String?
    
    var sentenceStore: SentenceStore
    var audioPlayer: AudioPlayable
    var tts: TTSService
    
    init(
        sentenceStore: SentenceStore,
        audioPlayer: AudioPlayable,
        tts: TTSService
    ) {
        self.sentenceStore = sentenceStore
        self.audioPlayer = audioPlayer
        self.tts = tts
    }
    
    func loadToday() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let entities = try await sentenceStore.fetchTodaysPack()
            items = entities.map { SentenceVM(from: $0) }
        } catch {
            errorMessage = "Failed to load today's sentences: \(error.localizedDescription)"
            print("Error loading sentences: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshDailySentences() async {
        print("🔄 Starting refresh...")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Calling sentenceStore.refreshDailySentences()...")
            try await sentenceStore.refreshDailySentences()
            print("🔄 Fetching today's pack...")
            let entities = try await sentenceStore.fetchTodaysPack()
            print("🔄 Got \(entities.count) entities, updating UI...")
            items = entities.map { SentenceVM(from: $0) }
            print("🔄 Successfully refreshed daily sentences with \(items.count) items")
            
            // Mark all sentences as viewed since user has seen them
            markSentencesAsViewed(entities.map { $0.id })
        } catch {
            errorMessage = "Failed to refresh sentences: \(error.localizedDescription)"
            print("❌ Error refreshing sentences: \(error)")
        }
        
        isLoading = false
        print("🔄 Refresh complete, isLoading = false")
    }
    
    func toggleExpanded(_ id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedID == id {
                expandedID = nil
            } else {
                expandedID = id
            }
        }
    }
    
    private func markSentencesAsViewed(_ ids: [String]) {
        var viewedSentences = UserDefaults.standard.array(forKey: "viewed_sentences") as? [String] ?? []
        
        // Add each sentence ID to the front of the list
        for id in ids.reversed() { // Reverse to maintain order when adding to front
            // Remove if already exists
            viewedSentences.removeAll { $0 == id }
            // Add to front
            viewedSentences.insert(id, at: 0)
        }
        
        // Keep only last 100
        if viewedSentences.count > 100 {
            viewedSentences = Array(viewedSentences.prefix(100))
        }
        
        UserDefaults.standard.set(viewedSentences, forKey: "viewed_sentences")
    }
    
    private func markSentenceAsViewed(_ id: String) {
        markSentencesAsViewed([id])
    }
    
    func playAudio(for id: String) {
        guard let sentence = items.first(where: { $0.id == id }) else { return }
        
        if let audioURL = sentence.audioURL {
            currentlyPlayingID = id
            Task {
                await audioPlayer.play(url: audioURL)
                await MainActor.run {
                    self.currentlyPlayingID = nil
                }
            }
        }
    }
    
    func speakTTS(for id: String) {
        guard let sentence = items.first(where: { $0.id == id }) else { return }
        
        currentlyPlayingID = id
        Task {
            await tts.speak(sentence.hanzi, language: "zh-CN")
            await MainActor.run {
                self.currentlyPlayingID = nil
            }
        }
    }
    
    func stopAudio() {
        audioPlayer.stop()
        tts.stop()
        currentlyPlayingID = nil
    }
    
    func recordPronunciation(for id: String) {
        guard let sentence = items.first(where: { $0.id == id }) else { return }
        
        // TODO: Implement recording functionality
        // This will be connected to the recording services
        print("🎤 Recording pronunciation for: \(sentence.hanzi)")
    }
    
    func context(for id: String) -> (previous: SentenceVM?, next: SentenceVM?) {
        guard let currentIndex = items.firstIndex(where: { $0.id == id }) else {
            return (nil, nil)
        }
        
        let previous = currentIndex > 0 ? items[currentIndex - 1] : nil
        let next = currentIndex < items.count - 1 ? items[currentIndex + 1] : nil
        
        return (previous, next)
    }
    
    var totalSentences: Int {
        return items.count
    }
}