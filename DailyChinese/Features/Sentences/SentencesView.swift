import SwiftUI
import Foundation


struct SentencesView: View {
    @Environment(\.di) private var di
    @StateObject private var viewModel: SentencesViewModel
    @State private var isSimplified = true
    
    init() {
        _viewModel = StateObject(wrappedValue: SentencesViewModel(
            sentenceStore: InMemoryRepository(),
            audioPlayer: AudioPlayer(),
            tts: AVSpeechTTSService()
        ))
    }
    
    init(viewModel: SentencesViewModel) {
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
                
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView("Loading sentences...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.white)
                } else if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    ZStack(alignment: .top) {
                        contentView
                        
                        // Subtle refresh indicator
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Refreshing...")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.primary)
                            .cornerRadius(16)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("")
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
                    
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        Task {
                            await viewModel.refreshDailySentences()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                
            }
        }
        .task {
            await loadData()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
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
        .refreshable {
            await viewModel.refreshDailySentences()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No sentences for today")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Pull to refresh or check back tomorrow")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    
    private func loadData() async {
        await viewModel.loadToday()
    }
    
}

#Preview("With Data") {
    let container = DIContainer.preview
    SentencesView(viewModel: SentencesViewModel(
        sentenceStore: container.sentenceStore,
        audioPlayer: container.audioPlayer,
        tts: container.tts
    ))
    .environment(\.di, container)
}

#Preview("Empty State") {
    let container = DIContainer.empty
    SentencesView(viewModel: SentencesViewModel(
        sentenceStore: container.sentenceStore,
        audioPlayer: container.audioPlayer,
        tts: container.tts
    ))
    .environment(\.di, container)
}