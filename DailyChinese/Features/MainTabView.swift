import SwiftUI

struct MainTabView: View {
    private let container: DIContainer
    
    init(container: DIContainer) {
        self.container = container
    }
    
    var body: some View {
        TabView {
            SentencesView(viewModel: SentencesViewModel(
                sentenceStore: container.sentenceStore,
                audioPlayer: container.audioPlayer,
                tts: container.tts
            ))
            .tabItem {
                Label("Today", systemImage: "calendar")
            }
            
            SingleSentenceView(viewModel: SingleSentenceViewModel(
                sentenceStore: container.sentenceStore,
                audioPlayer: container.audioPlayer,
                tts: container.tts
            ))
            .tabItem {
                Label("Practice", systemImage: "star")
            }
            
            HistoryView(viewModel: HistoryViewModel(
                sentenceStore: container.sentenceStore,
                audioPlayer: container.audioPlayer,
                tts: container.tts
            ))
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
        }
        .accentColor(.white)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView(container: DIContainer.preview)
}