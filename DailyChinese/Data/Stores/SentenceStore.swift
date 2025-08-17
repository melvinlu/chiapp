import Foundation

protocol SentenceStore {
    func fetchPack(for date: Date) async throws -> [SentenceEntity]
    func fetchAllSentences(for date: Date) async throws -> [SentenceEntity]
    func upsert(_ sentence: SentenceEntity) async throws
    func delete(_ sentence: SentenceEntity) async throws
    func toggleLearned(id: String) async throws
    func toggleFavorite(id: String) async throws
    func seedIfEmpty() async throws
    func refreshDailySentences() async throws
}

extension SentenceStore {
    func fetchTodaysPack() async throws -> [SentenceEntity] {
        try await fetchPack(for: Date())
    }
}