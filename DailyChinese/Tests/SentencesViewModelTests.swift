import XCTest
@testable import DailyChinese

@MainActor
final class SentencesViewModelTests: XCTestCase {
    var viewModel: SentencesViewModel!
    var mockStore: InMemoryRepository!
    var mockAudioPlayer: MockAudioPlayer!
    var mockTTS: MockTTSService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let today = Date()
        let testSentences = [
            SentenceEntity(
                id: "test-01",
                hanzi: "测试句子一",
                pinyin: "Cèshì jùzi yī",
                english: "Test sentence one",
                packDate: today,
                indexInPack: 1,
                audioURL: URL(string: "test://audio1.m4a")
            ),
            SentenceEntity(
                id: "test-02",
                hanzi: "测试句子二",
                pinyin: "Cèshì jùzi èr",
                english: "Test sentence two",
                packDate: today,
                indexInPack: 2
            ),
            SentenceEntity(
                id: "test-03",
                hanzi: "测试句子三",
                pinyin: "Cèshì jùzi sān",
                english: "Test sentence three",
                packDate: today,
                indexInPack: 3
            )
        ]
        
        mockStore = InMemoryRepository(sentences: testSentences)
        mockAudioPlayer = MockAudioPlayer()
        mockTTS = MockTTSService()
        
        viewModel = SentencesViewModel(
            sentenceStore: mockStore,
            audioPlayer: mockAudioPlayer,
            tts: mockTTS
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockStore = nil
        mockAudioPlayer = nil
        mockTTS = nil
        super.tearDown()
    }
    
    func testLoadTodayFetchesSentences() async {
        await viewModel.loadToday()
        
        XCTAssertEqual(viewModel.items.count, 3)
        XCTAssertEqual(viewModel.items[0].hanzi, "测试句子一")
        XCTAssertEqual(viewModel.items[1].hanzi, "测试句子二")
        XCTAssertEqual(viewModel.items[2].hanzi, "测试句子三")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testToggleExpanded() {
        viewModel.items = [
            SentenceVM(from: SentenceEntity(
                id: "1",
                hanzi: "Test",
                pinyin: "Test",
                english: "Test",
                packDate: Date(),
                indexInPack: 1
            ))
        ]
        
        XCTAssertNil(viewModel.expandedID)
        
        viewModel.toggleExpanded("1")
        XCTAssertEqual(viewModel.expandedID, "1")
        
        viewModel.toggleExpanded("1")
        XCTAssertNil(viewModel.expandedID)
    }
    
    func testToggleLearned() async {
        await viewModel.loadToday()
        
        let firstItem = viewModel.items[0]
        XCTAssertFalse(firstItem.isLearned)
        
        await viewModel.toggleLearned(firstItem.id)
        await viewModel.loadToday()
        
        let updatedItem = viewModel.items[0]
        XCTAssertTrue(updatedItem.isLearned)
    }
    
    func testToggleFavorite() async {
        await viewModel.loadToday()
        
        let firstItem = viewModel.items[0]
        XCTAssertFalse(firstItem.isFavorite)
        
        await viewModel.toggleFavorite(firstItem.id)
        await viewModel.loadToday()
        
        let updatedItem = viewModel.items[0]
        XCTAssertTrue(updatedItem.isFavorite)
    }
    
    func testContextCalculation() async {
        await viewModel.loadToday()
        
        let firstContext = viewModel.context(for: "test-01")
        XCTAssertNil(firstContext.previous)
        XCTAssertEqual(firstContext.next?.id, "test-02")
        
        let middleContext = viewModel.context(for: "test-02")
        XCTAssertEqual(middleContext.previous?.id, "test-01")
        XCTAssertEqual(middleContext.next?.id, "test-03")
        
        let lastContext = viewModel.context(for: "test-03")
        XCTAssertEqual(lastContext.previous?.id, "test-02")
        XCTAssertNil(lastContext.next)
    }
    
    func testStatisticsAndProgress() async {
        await viewModel.loadToday()
        
        XCTAssertEqual(viewModel.statistics.total, 3)
        XCTAssertEqual(viewModel.statistics.learned, 0)
        XCTAssertEqual(viewModel.progress, 0.0)
        
        await viewModel.toggleLearned("test-01")
        await viewModel.toggleLearned("test-02")
        await viewModel.loadToday()
        
        XCTAssertEqual(viewModel.statistics.learned, 2)
        XCTAssertEqual(viewModel.progress, 2.0 / 3.0, accuracy: 0.01)
    }
    
    func testPlayAudioWithURL() async {
        await viewModel.loadToday()
        
        viewModel.playAudio(for: "test-01")
        
        XCTAssertEqual(viewModel.currentlyPlayingID, "test-01")
        XCTAssertTrue(mockAudioPlayer.playWasCalled)
        XCTAssertEqual(mockAudioPlayer.lastPlayedURL?.absoluteString, "test://audio1.m4a")
    }
    
    func testSpeakTTSWithoutAudioURL() async {
        await viewModel.loadToday()
        
        viewModel.speakTTS(for: "test-02")
        
        XCTAssertEqual(viewModel.currentlyPlayingID, "test-02")
        XCTAssertTrue(mockTTS.speakWasCalled)
        XCTAssertEqual(mockTTS.lastSpokenText, "测试句子二")
        XCTAssertEqual(mockTTS.lastLanguage, "zh-CN")
    }
    
    func testStopAudio() {
        viewModel.currentlyPlayingID = "test"
        
        viewModel.stopAudio()
        
        XCTAssertNil(viewModel.currentlyPlayingID)
        XCTAssertTrue(mockAudioPlayer.stopWasCalled)
        XCTAssertTrue(mockTTS.stopWasCalled)
    }
}

class MockAudioPlayer: AudioPlayable {
    var isPlaying = false
    var playWasCalled = false
    var stopWasCalled = false
    var lastPlayedURL: URL?
    
    func play(url: URL) async {
        playWasCalled = true
        lastPlayedURL = url
        isPlaying = true
    }
    
    func stop() {
        stopWasCalled = true
        isPlaying = false
    }
}

class MockTTSService: TTSService {
    var isSpeaking = false
    var speakWasCalled = false
    var stopWasCalled = false
    var lastSpokenText: String?
    var lastLanguage: String?
    
    func speak(_ text: String, language: String) async {
        speakWasCalled = true
        lastSpokenText = text
        lastLanguage = language
        isSpeaking = true
    }
    
    func stop() {
        stopWasCalled = true
        isSpeaking = false
    }
}