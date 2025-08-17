import Foundation
import SwiftData

final class LocalRepository: SentenceStore {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchPack(for date: Date) async throws -> [SentenceEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Get all sentences for the day
        let allDescriptor = FetchDescriptor<SentenceEntity>(
            predicate: #Predicate { sentence in
                sentence.packDate >= startOfDay && sentence.packDate < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let allSentences = try modelContext.fetch(allDescriptor)
        
        // Simply return the 5 most recent sentences, sorted by creation time (newest first), then by indexInPack
        let sortedSentences = allSentences.sorted { first, second in
            // Primary sort: by creation time (newest first)
            let firstTime = first.createdAt ?? Date.distantPast
            let secondTime = second.createdAt ?? Date.distantPast
            
            if firstTime != secondTime {
                return firstTime > secondTime
            }
            
            // Secondary sort: by indexInPack (ascending) for sentences created at the same time
            return first.indexInPack < second.indexInPack
        }
        
        return Array(sortedSentences.prefix(5))
    }
    
    func fetchAllSentences(for date: Date) async throws -> [SentenceEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<SentenceEntity>(
            predicate: #Predicate { sentence in
                sentence.packDate >= startOfDay && sentence.packDate < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func upsert(_ sentence: SentenceEntity) async throws {
        modelContext.insert(sentence)
        try modelContext.save()
    }
    
    func toggleLearned(id: String) async throws {
        guard let sentence = try fetchSentence(by: id) else { return }
        sentence.isLearned.toggle()
        try modelContext.save()
    }
    
    func toggleFavorite(id: String) async throws {
        guard let sentence = try fetchSentence(by: id) else { return }
        sentence.isFavorite.toggle()
        try modelContext.save()
    }
    
    func delete(_ sentence: SentenceEntity) async throws {
        modelContext.delete(sentence)
        try modelContext.save()
    }
    
    func seedIfEmpty() async throws {
        let descriptor = FetchDescriptor<SentenceEntity>()
        let existingEntities = try modelContext.fetch(descriptor)
        guard existingEntities.isEmpty else { return }
        
        guard let url = Bundle.main.url(forResource: "seed_today", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load seed data")
            return
        }
        
        let decoder = JSONDecoder()
        let packDTO = try decoder.decode(DailyPackDTO.self, from: data)
        
        for sentenceDTO in packDTO.sentences {
            let entity = sentenceDTO.toEntity(packDate: packDTO.packDate)
            modelContext.insert(entity)
        }
        
        try modelContext.save()
    }
    
    func refreshDailySentences() async throws {
        print("LocalRepository does not support refreshing - use NetworkRepository instead")
    }
    
    private func fetchSentence(by id: String) throws -> SentenceEntity? {
        let descriptor = FetchDescriptor<SentenceEntity>(
            predicate: #Predicate { sentence in
                sentence.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
}

final class InMemoryRepository: SentenceStore {
    private var sentences: [SentenceEntity] = []
    
    init(sentences: [SentenceEntity] = []) {
        self.sentences = sentences
    }
    
    func fetchPack(for date: Date) async throws -> [SentenceEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let filteredSentences = sentences.filter { $0.packDate >= startOfDay && $0.packDate < endOfDay }
        
        // Simply return the 5 most recent sentences, sorted by creation time (newest first), then by indexInPack
        let sortedSentences = filteredSentences.sorted { first, second in
            // Primary sort: by creation time (newest first)
            let firstTime = first.createdAt ?? Date.distantPast
            let secondTime = second.createdAt ?? Date.distantPast
            
            if firstTime != secondTime {
                return firstTime > secondTime
            }
            
            // Secondary sort: by indexInPack (ascending) for sentences created at the same time
            return first.indexInPack < second.indexInPack
        }
        
        return Array(sortedSentences.prefix(5))
    }
    
    func fetchAllSentences(for date: Date) async throws -> [SentenceEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return sentences
            .filter { $0.packDate >= startOfDay && $0.packDate < endOfDay }
            .sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
    
    func upsert(_ sentence: SentenceEntity) async throws {
        if let index = sentences.firstIndex(where: { $0.id == sentence.id }) {
            sentences[index] = sentence
        } else {
            sentences.append(sentence)
        }
    }
    
    func toggleLearned(id: String) async throws {
        guard let index = sentences.firstIndex(where: { $0.id == id }) else { return }
        sentences[index].isLearned.toggle()
    }
    
    func toggleFavorite(id: String) async throws {
        guard let index = sentences.firstIndex(where: { $0.id == id }) else { return }
        sentences[index].isFavorite.toggle()
    }
    
    func delete(_ sentence: SentenceEntity) async throws {
        sentences.removeAll { $0.id == sentence.id }
    }
    
    func seedIfEmpty() async throws {
        guard sentences.isEmpty else { return }
        sentences = Self.mockSentences()
    }
    
    func refreshDailySentences() async throws {
        sentences = Self.mockSentences()
        print("InMemoryRepository refreshed with mock sentences")
    }
    
    static func mockSentences() -> [SentenceEntity] {
        let today = Date()
        return [
            SentenceEntity(
                id: "mock-01",
                hanzi: "我在北京工作了三年，现在想回家乡发展。",
                pinyin: "Wǒ zài Běijīng gōngzuòle sān nián, xiànzài xiǎng huí jiāxiāng fāzhǎn.",
                english: "I've worked in Beijing for three years, and now I want to go back to my hometown to develop my career.",
                packDate: today,
                indexInPack: 1
            ),
            SentenceEntity(
                id: "mock-02",
                hanzi: "这道菜有点儿咸，不过味道还不错。",
                pinyin: "Zhè dào cài yǒu diǎnr xián, búguò wèidào hái búcuò.",
                english: "This dish is a bit salty, but the flavor is still pretty good.",
                packDate: today,
                indexInPack: 2
            ),
            SentenceEntity(
                id: "mock-03",
                hanzi: "由于交通堵塞，我迟到了半个小时。",
                pinyin: "Yóuyú jiāotōng dǔsè, wǒ chídàole bàn gè xiǎoshí.",
                english: "Due to traffic congestion, I was half an hour late.",
                packDate: today,
                indexInPack: 3
            ),
            SentenceEntity(
                id: "mock-04",
                hanzi: "她不仅会说英语，还会说法语和德语。",
                pinyin: "Tā bùjǐn huì shuō Yīngyǔ, hái huì shuō Fǎyǔ hé Déyǔ.",
                english: "She not only speaks English, but also speaks French and German.",
                packDate: today,
                indexInPack: 4
            ),
            SentenceEntity(
                id: "mock-05",
                hanzi: "虽然今天下雨，但是我们的计划不会改变。",
                pinyin: "Suīrán jīntiān xiàyǔ, dànshì wǒmen de jìhuà bù huì gǎibiàn.",
                english: "Although it's raining today, our plans won't change.",
                packDate: today,
                indexInPack: 5
            )
        ]
    }
}