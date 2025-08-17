import SwiftUI
import SwiftData

@main
struct DailyChineseApp: App {
    private let container: DIContainer
    private let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                SentenceEntity.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            self.container = DIContainer.production(modelContext: modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView(container: container)
                .environment(\.di, container)
                .modelContainer(modelContainer)
                .task {
                    await seedDataIfNeeded()
                }
        }
    }
    
    private func seedDataIfNeeded() async {
        do {
            try await container.sentenceStore.seedIfEmpty()
        } catch {
            print("Failed to seed data: \(error)")
        }
    }
}