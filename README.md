# DailyChinese iOS App

A modern iOS application for learning Chinese through daily sentence practice, featuring AI-powered pronunciation grading, text-to-speech, and personalized learning experiences.

## 🎯 Overview

DailyChinese helps users learn Chinese by providing curated daily sentences with:
- **Daily Practice**: New sentences every day from various sources
- **AI Pronunciation Grading**: OpenAI-powered feedback on pronunciation
- **Text-to-Speech**: High-quality audio playback for proper pronunciation
- **Progress Tracking**: Monitor learning progress and maintain streaks
- **Offline Support**: Local fallback when network is unavailable

## 🏗️ Architecture

### Clean Architecture + MVVM

The app follows Clean Architecture principles with MVVM pattern for a maintainable, testable, and scalable codebase.

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │   Views     │◄──►│ ViewModels  │◄──►│   Models    │ │
│  │ (SwiftUI)   │    │(@Published) │    │ (Entities)  │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                    Business Layer                       │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │ Repositories│◄──►│  Services   │◄──►│   Config    │ │
│  │(Store Proto)│    │(TTS, AI)    │    │(AppConfig)  │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │   Local     │    │   Network   │    │   External  │ │
│  │  Storage    │    │    APIs     │    │  Services   │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
DailyChinese/
├── 📱 App/
│   └── DailyChineseApp.swift          # App entry point
│
├── 💾 Data/
│   ├── DTO/                           # Data Transfer Objects
│   │   └── SentenceDTO.swift
│   ├── Models/                        # Core data models
│   │   ├── DailyPack.swift
│   │   └── Sentence.swift
│   └── Stores/                        # Repository implementations
│       ├── LocalRepository.swift      # Local data management
│       ├── NetworkRepository.swift    # Network data fetching
│       └── SentenceStore.swift        # Repository protocol
│
├── ✨ Features/                       # Feature modules
│   ├── Audio/
│   │   └── AudioPlayer.swift          # Audio playback service
│   ├── History/
│   │   ├── HistoryView.swift          # Learning history UI
│   │   └── HistoryViewModel.swift     # History business logic
│   ├── Recording/
│   │   └── RecorderService.swift      # Voice recording
│   ├── Sentences/                     # Main feature
│   │   ├── SentencesView.swift        # Main sentences display
│   │   ├── SentencesViewModel.swift   # Sentences business logic
│   │   ├── SentenceDetailView.swift   # Individual sentence detail
│   │   └── SentenceRowView.swift      # Sentence list item
│   ├── Settings/
│   │   └── SettingsView.swift         # App configuration
│   └── MainTabView.swift              # Main navigation
│
├── 🔧 Services/                       # External service integrations
│   ├── AI/
│   │   └── AIService.swift            # AI service abstractions
│   ├── PronunciationGrading/
│   │   └── PronunciationGradingService.swift  # OpenAI pronunciation analysis
│   ├── SpeechRecognition/
│   │   └── SpeechRecognitionService.swift     # Speech-to-text
│   └── TTS/                           # Text-to-speech services
│       ├── TTSService.swift           # TTS protocol
│       ├── OpenAITTSService.swift     # OpenAI TTS implementation
│       └── HybridTTSService.swift     # System + OpenAI hybrid
│
├── ⚙️ System/
│   ├── AppConfig.swift                # Centralized configuration
│   └── DIContainer.swift              # Dependency injection
│
└── 🛠️ Utils/                          # Shared utilities
```

## 🔄 Data Flow

### 1. Sentence Loading Flow
```
User Opens App
      ↓
SentencesView appears
      ↓
SentencesViewModel.loadSentences()
      ↓
Repository.fetchPack(for: today)
      ↓
NetworkRepository tries ChatGPT API
      ↓
Falls back to LocalRepository if needed
      ↓
Data flows back to UI via @Published
```

### 2. Pronunciation Grading Flow
```
User Records Audio
      ↓
SpeechRecognitionService converts to text
      ↓
PronunciationGradingService.gradePronounciation()
      ↓
OpenAI API analyzes pronunciation
      ↓
Returns PronunciationGrade with score/feedback
      ↓
UI displays results with visual feedback
```

## 🏛️ Key Architectural Patterns

### Repository Pattern
Abstracts data access and provides a clean interface for data operations:

```swift
protocol SentenceStore {
    func fetchPack(for date: Date) async throws -> [SentenceEntity]
    func upsert(_ sentence: SentenceEntity) async throws
    func toggleLearned(id: String) async throws
}

// Multiple implementations
class LocalRepository: SentenceStore { }
class NetworkRepository: SentenceStore {
    private let fallbackRepository: LocalRepository
    // Network-first with local fallback
}
```

### Service-Oriented Architecture
External integrations are abstracted behind service protocols:

```swift
protocol TTSService {
    func speak(_ text: String, language: String) async
    func stop()
}

// Multiple implementations
class OpenAITTSService: TTSService { }
class HybridTTSService: TTSService {
    // Combines system TTS with OpenAI for better quality
}
```

### Dependency Injection
Clean dependency management with testable architecture:

```swift
class DIContainer {
    lazy var sentenceStore: SentenceStore = NetworkRepository(
        fallbackRepository: LocalRepository()
    )
    
    lazy var ttsService: TTSService = HybridTTSService()
    lazy var pronunciationService: PronunciationGradingService = 
        OpenAIPronunciationGradingService()
}
```

## 🔗 External Integrations

### OpenAI Services
- **ChatGPT API**: Generates daily Chinese sentences with context
- **TTS API**: High-quality Chinese pronunciation audio
- **Grading API**: Analyzes pronunciation accuracy

### Apple Frameworks
- **SwiftUI**: Modern declarative UI framework
- **Speech Framework**: Speech recognition for pronunciation practice
- **AVFoundation**: Audio recording and playback
- **Combine**: Reactive programming for data flow

## 🔒 Security & Configuration

### API Key Management
- Secure storage in `config.json` (gitignored)
- Environment variable support for CI/CD
- User preference override capability
- Fallback mechanisms for missing credentials

### Data Protection
- No sensitive user data stored remotely
- Local encryption for user preferences
- Secure network communications (HTTPS only)
- Input validation and sanitization

## 🧪 Testing Strategy

### Test Pyramid
```
        🔺 UI Tests
       ────────────
      🔺🔺 Integration Tests  
     ──────────────────────
    🔺🔺🔺🔺 Unit Tests
   ────────────────────────
```

### Testing Patterns
- **Unit Tests**: Individual component testing with mocks
- **Integration Tests**: Repository and service interaction testing
- **UI Tests**: Critical user workflow validation

### Mock Implementations
```swift
class MockSentenceStore: SentenceStore {
    var mockSentences: [SentenceEntity] = []
    
    func fetchPack(for date: Date) async throws -> [SentenceEntity] {
        return mockSentences
    }
}
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ target
- OpenAI API key (optional, has fallbacks)

### Setup
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chiapp
   ```

2. **Configure API Key** (Optional)
   ```bash
   echo '{"openai_api_key": "your-api-key-here"}' > config.json
   ```

3. **Open in Xcode**
   ```bash
   open DailyChinese.xcodeproj
   ```

4. **Build and Run**
   - Select target device/simulator
   - Press ⌘+R to build and run

### Configuration Options

**Environment Variables:**
- `OPENAI_API_KEY`: API key for OpenAI services

**User Settings:**
- TTS rate and pitch adjustment
- Daily sentence count preference
- AI features toggle
- Recording features toggle

## 📈 Performance Considerations

### Memory Management
- Proper retain cycle prevention with `weak` references
- Efficient image and audio data handling
- Background queue processing for heavy operations

### Network Optimization
- Request caching and retry logic
- Offline-first architecture with local fallbacks
- Efficient API usage with appropriate timeouts

### UI Performance
- Lazy loading for large datasets
- Efficient list rendering with SwiftUI
- Proper state management to minimize re-renders

## 🔮 Future Enhancements

### Planned Features
- **Spaced Repetition**: Advanced learning algorithm
- **Community Features**: Shared learning experiences
- **Advanced Analytics**: Detailed progress insights
- **Gamification**: Streaks, achievements, and rewards

### Technical Improvements
- **Core Data Migration**: Enhanced local storage
- **Widget Support**: Home screen sentence widgets
- **Watch App**: Apple Watch companion
- **Internationalization**: Multi-language support

## 🤝 Contributing

### Development Workflow
1. Read `CLAUDE.md` for detailed guidelines
2. Create feature branch from `main`
3. Follow established patterns and conventions
4. Add tests for new functionality
5. Submit pull request with detailed description

### Code Standards
- Follow Swift API Design Guidelines
- Use SwiftLint for consistent formatting
- Write comprehensive tests
- Document public APIs
- Follow established architectural patterns

## 📄 License

[License information to be added]

## 📞 Support

For questions, issues, or contributions, please refer to the project's issue tracker and contribution guidelines.

---

**Built with ❤️ for Chinese language learners**