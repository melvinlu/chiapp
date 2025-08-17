import SwiftUI
import SwiftData


struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var isSimplified = true
    
    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading history...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.white)
                } else if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSimplified.toggle()
                    }) {
                        Text(isSimplified ? "简" : "繁")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                }
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items) { item in
                    SentenceRowView(
                        sentence: item,
                        isExpanded: viewModel.expandedID == item.id,
                        isPlaying: viewModel.currentlyPlayingID == item.id,
                        context: viewModel.context(for: item.id),
                        isSimplified: isSimplified,
                        onTap: { viewModel.toggleExpanded(item.id) },
                        onPlayAudio: { viewModel.playAudio(for: item.id) },
                        onSpeakTTS: { viewModel.speakTTS(for: item.id) },
                        onStopAudio: { viewModel.stopAudio() },
                        onRecord: { viewModel.recordPronunciation(for: item.id) }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    let container = DIContainer.preview
    HistoryView(viewModel: HistoryViewModel(
        sentenceStore: container.sentenceStore,
        audioPlayer: container.audioPlayer,
        tts: container.tts
    ))
}