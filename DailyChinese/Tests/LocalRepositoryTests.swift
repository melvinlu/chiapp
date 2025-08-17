import XCTest
import SwiftData
@testable import DailyChinese

final class LocalRepositoryTests: XCTestCase {
    var repository: LocalRepository!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([SentenceEntity.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        modelContext = modelContainer.mainContext
        repository = LocalRepository(modelContext: modelContext)
    }
    
    override func tearDown() {
        repository = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    func testFetchPackForDate() async throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todaysSentences = [
            SentenceEntity(
                id: "today-1",
                hanzi: "今天的句子",
                pinyin: "Jīntiān de jùzi",
                english: "Today's sentence",
                packDate: today,
                indexInPack: 1
            ),
            SentenceEntity(
                id: "today-2",
                hanzi: "另一个今天的句子",
                pinyin: "Lìng yīgè jīntiān de jùzi",
                english: "Another today's sentence",
                packDate: today,
                indexInPack: 2
            )
        ]
        
        let yesterdaysSentence = SentenceEntity(
            id: "yesterday-1",
            hanzi: "昨天的句子",
            pinyin: "Zuótiān de jùzi",
            english: "Yesterday's sentence",
            packDate: yesterday,
            indexInPack: 1
        )
        
        for sentence in todaysSentences {
            modelContext.insert(sentence)
        }
        modelContext.insert(yesterdaysSentence)
        try modelContext.save()
        
        let fetchedToday = try await repository.fetchPack(for: today)
        XCTAssertEqual(fetchedToday.count, 2)
        XCTAssertEqual(fetchedToday[0].id, "today-1")
        XCTAssertEqual(fetchedToday[1].id, "today-2")
        
        let fetchedYesterday = try await repository.fetchPack(for: yesterday)
        XCTAssertEqual(fetchedYesterday.count, 1)
        XCTAssertEqual(fetchedYesterday[0].id, "yesterday-1")
    }
    
    func testUpsert() async throws {
        let sentence = SentenceEntity(
            id: "upsert-test",
            hanzi: "测试句子",
            pinyin: "Cèshì jùzi",
            english: "Test sentence",
            packDate: Date(),
            indexInPack: 1
        )
        
        try await repository.upsert(sentence)
        
        let fetched = try await repository.fetchPack(for: Date())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].id, "upsert-test")
    }
    
    func testToggleLearned() async throws {
        let sentence = SentenceEntity(
            id: "toggle-learned",
            hanzi: "学习句子",
            pinyin: "Xuéxí jùzi",
            english: "Learning sentence",
            packDate: Date(),
            indexInPack: 1,
            isLearned: false
        )
        
        modelContext.insert(sentence)
        try modelContext.save()
        
        try await repository.toggleLearned(id: "toggle-learned")
        
        let fetched = try await repository.fetchPack(for: Date())
        XCTAssertTrue(fetched[0].isLearned)
        
        try await repository.toggleLearned(id: "toggle-learned")
        let fetchedAgain = try await repository.fetchPack(for: Date())
        XCTAssertFalse(fetchedAgain[0].isLearned)
    }
    
    func testToggleFavorite() async throws {
        let sentence = SentenceEntity(
            id: "toggle-favorite",
            hanzi: "收藏句子",
            pinyin: "Shōucáng jùzi",
            english: "Favorite sentence",
            packDate: Date(),
            indexInPack: 1,
            isFavorite: false
        )
        
        modelContext.insert(sentence)
        try modelContext.save()
        
        try await repository.toggleFavorite(id: "toggle-favorite")
        
        let fetched = try await repository.fetchPack(for: Date())
        XCTAssertTrue(fetched[0].isFavorite)
        
        try await repository.toggleFavorite(id: "toggle-favorite")
        let fetchedAgain = try await repository.fetchPack(for: Date())
        XCTAssertFalse(fetchedAgain[0].isFavorite)
    }
    
    func testSortByIndexInPack() async throws {
        let today = Date()
        let sentences = [
            SentenceEntity(
                id: "3",
                hanzi: "第三",
                pinyin: "Dì sān",
                english: "Third",
                packDate: today,
                indexInPack: 3
            ),
            SentenceEntity(
                id: "1",
                hanzi: "第一",
                pinyin: "Dì yī",
                english: "First",
                packDate: today,
                indexInPack: 1
            ),
            SentenceEntity(
                id: "2",
                hanzi: "第二",
                pinyin: "Dì èr",
                english: "Second",
                packDate: today,
                indexInPack: 2
            )
        ]
        
        for sentence in sentences {
            modelContext.insert(sentence)
        }
        try modelContext.save()
        
        let fetched = try await repository.fetchPack(for: today)
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched[0].id, "1")
        XCTAssertEqual(fetched[1].id, "2")
        XCTAssertEqual(fetched[2].id, "3")
    }
}

final class InMemoryRepositoryTests: XCTestCase {
    var repository: InMemoryRepository!
    
    override func setUp() {
        super.setUp()
        repository = InMemoryRepository()
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testFetchPackFiltersbyDate() async throws {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todaysSentence = SentenceEntity(
            id: "today",
            hanzi: "今天",
            pinyin: "Jīntiān",
            english: "Today",
            packDate: today,
            indexInPack: 1
        )
        
        let tomorrowsSentence = SentenceEntity(
            id: "tomorrow",
            hanzi: "明天",
            pinyin: "Míngtiān",
            english: "Tomorrow",
            packDate: tomorrow,
            indexInPack: 1
        )
        
        try await repository.upsert(todaysSentence)
        try await repository.upsert(tomorrowsSentence)
        
        let fetchedToday = try await repository.fetchPack(for: today)
        XCTAssertEqual(fetchedToday.count, 1)
        XCTAssertEqual(fetchedToday[0].id, "today")
        
        let fetchedTomorrow = try await repository.fetchPack(for: tomorrow)
        XCTAssertEqual(fetchedTomorrow.count, 1)
        XCTAssertEqual(fetchedTomorrow[0].id, "tomorrow")
    }
    
    func testSeedIfEmpty() async throws {
        XCTAssertTrue((try await repository.fetchPack(for: Date())).isEmpty)
        
        try await repository.seedIfEmpty()
        
        let fetched = try await repository.fetchPack(for: Date())
        XCTAssertFalse(fetched.isEmpty)
        XCTAssertEqual(fetched.count, 3)
    }
    
    func testSeedIfEmptyDoesNotOverwrite() async throws {
        let sentence = SentenceEntity(
            id: "existing",
            hanzi: "存在的",
            pinyin: "Cúnzài de",
            english: "Existing",
            packDate: Date(),
            indexInPack: 1
        )
        
        try await repository.upsert(sentence)
        try await repository.seedIfEmpty()
        
        let fetched = try await repository.fetchPack(for: Date())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].id, "existing")
    }
}