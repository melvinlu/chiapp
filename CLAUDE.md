# Claude Engineering Guidelines for DailyChinese

This document outlines the engineering practices, architecture principles, and development guidelines for the DailyChinese iOS application.

## 🏗️ Architecture Principles

### 1. Clean Architecture
- **Separation of Concerns**: Each layer has a single responsibility
- **Dependency Inversion**: High-level modules don't depend on low-level modules
- **Data Flow**: Unidirectional data flow from UI → ViewModel → Repository → Service

### 2. MVVM Pattern
- **Model**: Data entities and business logic
- **View**: SwiftUI views for UI presentation
- **ViewModel**: Business logic and state management

### 3. Repository Pattern
- Abstract data access behind repository interfaces
- Support multiple data sources (local, network, cache)
- Implement fallback strategies for offline functionality

### 4. Dependency Injection
- Use `DIContainer` for managing dependencies
- Enable easy testing with mock implementations
- Avoid singleton anti-patterns where possible

## 📁 Project Structure

```
DailyChinese/
├── App/                     # App lifecycle and entry point
├── Data/                    # Data layer
│   ├── DTO/                # Data Transfer Objects
│   ├── Models/             # Core data models
│   └── Stores/             # Repository implementations
├── Features/               # Feature modules
│   ├── Audio/              # Audio playback functionality
│   ├── History/            # Learning history
│   ├── Recording/          # Voice recording
│   ├── Sentences/          # Main sentence display
│   └── Settings/           # App configuration
├── Services/               # External service integrations
│   ├── AI/                 # AI service abstractions
│   ├── PronunciationGrading/ # Pronunciation analysis
│   ├── Recording/          # Audio recording services
│   ├── SpeechRecognition/  # Speech-to-text
│   └── TTS/                # Text-to-speech
├── System/                 # System configuration
└── Utils/                  # Shared utilities
```

## 🔧 Development Guidelines

### Code Organization

1. **Feature-Based Structure**: Group related functionality together
2. **Protocol-Oriented Programming**: Define interfaces before implementations
3. **Single Responsibility**: Each class/struct should have one reason to change
4. **Composition over Inheritance**: Prefer protocols and composition

### Naming Conventions

```swift
// Protocols
protocol SentenceStore { }
protocol TTSService { }

// Implementations
class LocalRepository: SentenceStore { }
class NetworkRepository: SentenceStore { }
class OpenAITTSService: TTSService { }

// ViewModels
class SentencesViewModel: ObservableObject { }

// Views
struct SentencesView: View { }
struct SentenceRowView: View { }
```

### Error Handling

```swift
// Define specific error types
enum NetworkError: Error, LocalizedError {
    case noAPIKey
    case httpError
    case decodingError
    
    var errorDescription: String? {
        // Provide user-friendly error messages
    }
}

// Use Result types for async operations
func fetchSentences() async -> Result<[Sentence], NetworkError>
```

### Configuration Management

```swift
// Centralized configuration
struct AppConfig {
    static let shared = AppConfig()
    
    // Environment-specific settings
    var isDebugMode: Bool { }
    var apiBaseURL: String { }
    var defaultLanguageCode: String { }
    
    // User preferences
    var ttsRate: Float { }
    var enableAIFeatures: Bool { }
}
```

## 🧪 Testing Guidelines

### Test Structure
- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **UI Tests**: Test user workflows (when applicable)

### Testing Patterns
```swift
class SentencesViewModelTests: XCTestCase {
    var viewModel: SentencesViewModel!
    var mockRepository: MockSentenceStore!
    
    override func setUp() {
        mockRepository = MockSentenceStore()
        viewModel = SentencesViewModel(repository: mockRepository)
    }
    
    func testFetchSentences() async {
        // Arrange
        let expectedSentences = [/* test data */]
        mockRepository.sentences = expectedSentences
        
        // Act
        await viewModel.loadSentences()
        
        // Assert
        XCTAssertEqual(viewModel.sentences.count, expectedSentences.count)
    }
}
```

## 🔒 Security Practices

### API Key Management
- **Never hardcode API keys** in source code
- Store sensitive data in `config.json` (gitignored)
- Use environment variables for CI/CD
- Implement fallback mechanisms for missing keys

### Data Protection
- Encrypt sensitive user data at rest
- Use HTTPS for all network communications
- Validate all external data inputs
- Implement proper error handling without exposing internals

## 🚀 Performance Guidelines

### Memory Management
- Use `weak` references to prevent retain cycles
- Dispose of heavy resources promptly
- Implement proper cleanup in `deinit`

### Network Optimization
- Implement caching strategies
- Use appropriate timeout values
- Handle offline scenarios gracefully
- Batch API requests when possible

### UI Performance
- Keep UI updates on main thread
- Use lazy loading for large datasets
- Implement proper list virtualization
- Minimize view hierarchy depth

## 📱 SwiftUI Best Practices

### View Composition
```swift
// Break down complex views into smaller components
struct SentenceDetailView: View {
    let sentence: Sentence
    
    var body: some View {
        VStack {
            SentenceHeaderView(sentence: sentence)
            SentenceContentView(sentence: sentence)
            SentenceActionsView(sentence: sentence)
        }
    }
}
```

### State Management
```swift
// Use appropriate property wrappers
@StateObject private var viewModel = SentencesViewModel()
@State private var isShowingDetail = false
@Binding var selectedSentence: Sentence?
@Environment(\.dismiss) private var dismiss
```

## 🔄 Data Flow Patterns

### Unidirectional Data Flow
1. **User Action** → View triggers action
2. **View** → Calls ViewModel method
3. **ViewModel** → Calls Repository/Service
4. **Repository** → Fetches/updates data
5. **Data** → Flows back through layers
6. **UI Update** → View observes ViewModel changes

### Repository Pattern Implementation
```swift
protocol SentenceStore {
    func fetchPack(for date: Date) async throws -> [SentenceEntity]
    func upsert(_ sentence: SentenceEntity) async throws
    func toggleLearned(id: String) async throws
}

class NetworkRepository: SentenceStore {
    private let fallbackRepository: LocalRepository
    
    // Implementation with fallback strategy
}
```

## 🔧 Tooling and Commands

### Build Commands
```bash
# Build the project
xcodebuild -scheme DailyChinese -configuration Debug

# Run tests
xcodebuild test -scheme DailyChinese -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for distribution
xcodebuild archive -scheme DailyChinese -archivePath DailyChinese.xcarchive
```

### Code Quality
- Use SwiftLint for consistent code style
- Run static analysis regularly
- Perform code reviews for all changes
- Maintain test coverage above 70%

## 📈 Scalability Considerations

### Modular Architecture
- Design features as independent modules
- Use protocols for module communication
- Implement feature flags for gradual rollouts
- Plan for horizontal scaling of services

### Database Design
- Use proper indexing for query performance
- Implement data migration strategies
- Consider partitioning for large datasets
- Plan for data archival and cleanup

### Service Integration
- Design fault-tolerant service interactions
- Implement circuit breaker patterns
- Use async processing for heavy operations
- Plan for service versioning and backward compatibility

## 🐛 Debugging and Monitoring

### Logging Strategy
```swift
// Structured logging with appropriate levels
print("🌐 NetworkRepository: Starting refresh...")
print("✅ Successfully fetched \(count) sentences")
print("❌ Failed to refresh: \(error)")
```

### Error Tracking
- Implement comprehensive error logging
- Track user experience metrics
- Monitor API response times
- Set up alerts for critical failures

## 🔄 Continuous Integration

### Pre-commit Checks
- Code formatting (SwiftFormat)
- Linting (SwiftLint)
- Unit test execution
- Security scan for hardcoded secrets

### Deployment Pipeline
1. Code commit triggers CI
2. Run automated tests
3. Build and archive
4. Deploy to TestFlight
5. Automated testing on devices
6. Release to App Store (manual approval)

## 📚 Documentation Standards

### Code Documentation
- Document public APIs with proper Swift documentation
- Include usage examples for complex functionality
- Maintain architecture decision records (ADRs)
- Keep README and CLAUDE.md up to date

### Change Management
- Use semantic versioning
- Maintain detailed changelog
- Document breaking changes
- Provide migration guides when needed

---

## 🎯 Key Principles Summary

1. **Maintainability**: Code should be easy to understand and modify
2. **Testability**: All components should be easily testable
3. **Scalability**: Architecture should support growth
4. **Security**: Protect user data and API credentials
5. **Performance**: Optimize for user experience
6. **Reliability**: Handle errors gracefully
7. **Modularity**: Build loosely coupled components
8. **Documentation**: Keep code and architecture well-documented

Remember: These guidelines are living documents. Update them as the project evolves and new patterns emerge.