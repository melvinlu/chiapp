import Foundation
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var items: [SentenceVM] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var expandedID: String?
    @Published var currentlyPlayingID: String?
    
    private let sentenceStore: SentenceStore
    private let audioPlayer: AudioPlayable
    private let tts: TTSService
    
    init(sentenceStore: SentenceStore, audioPlayer: AudioPlayable, tts: TTSService) {
        self.sentenceStore = sentenceStore
        self.audioPlayer = audioPlayer
        self.tts = tts
    }
    
    func loadHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all sentences from all dates and show chronologically
            var allSentences: [SentenceEntity] = []
            
            // Fetch from all dates (last 30 days)
            let calendar = Calendar.current
            for days in 0..<30 {
                let date = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
                let dayEntities = try await sentenceStore.fetchAllSentences(for: date)
                allSentences.append(contentsOf: dayEntities)
            }
            
            // Sort by creation time (newest first)
            let sortedHistory = allSentences.sorted { first, second in
                let firstTime = first.createdAt ?? Date.distantPast
                let secondTime = second.createdAt ?? Date.distantPast
                return firstTime > secondTime
            }
            
            items = sortedHistory.map { SentenceVM(from: $0) }
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleExpanded(_ id: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedID == id {
                expandedID = nil
            } else {
                expandedID = id
            }
        }
    }
    
    private func markSentenceAsViewed(_ id: String) {
        var viewedSentences = UserDefaults.standard.array(forKey: "viewed_sentences") as? [String] ?? []
        
        // Remove if already exists (to move to front)
        viewedSentences.removeAll { $0 == id }
        
        // Add to front
        viewedSentences.insert(id, at: 0)
        
        // Keep only last 100
        if viewedSentences.count > 100 {
            viewedSentences = Array(viewedSentences.prefix(100))
        }
        
        UserDefaults.standard.set(viewedSentences, forKey: "viewed_sentences")
    }
    
    func playAudio(for id: String) {
        guard let sentence = items.first(where: { $0.id == id }) else { return }
        
        if let audioURL = sentence.audioURL {
            Task {
                currentlyPlayingID = id
                await audioPlayer.play(url: audioURL)
                currentlyPlayingID = nil
            }
        }
    }
    
    func speakTTS(for id: String) {
        guard let sentence = items.first(where: { $0.id == id }) else { return }
        
        Task {
            currentlyPlayingID = id
            await tts.speak(sentence.hanzi, language: "zh-CN")
            currentlyPlayingID = nil
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
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return (nil, nil)
        }
        
        let previous = index > 0 ? items[index - 1] : nil
        let next = index < items.count - 1 ? items[index + 1] : nil
        
        return (previous, next)
    }
}