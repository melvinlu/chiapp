import SwiftUI

struct SingleSentenceView: View {
    @StateObject private var viewModel: SingleSentenceViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isFlipped = false
    
    init(viewModel: SingleSentenceViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Background - consistent with other pages
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if let sentence = viewModel.currentSentence {
                sentenceContent(sentence)
            } else {
                emptyStateView
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading sentences...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "text.bubble")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No sentences available")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Add some sentences to your daily practice to see them here!")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Refresh") {
                Task {
                    await viewModel.loadAllSentences()
                    await viewModel.loadRandomSentence()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
        }
        .padding()
    }
    
    private func sentenceContent(_ sentence: SentenceVM) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Previous card (left) - only if user can go back
                if let previousSentence = viewModel.previousSentencePreview {
                    cardView(previousSentence, showHints: false)
                        .offset(x: -geometry.size.width + dragOffset)
                        .opacity(isDragging && dragOffset > 0 ? min(1.0, dragOffset / 150.0) : 0.0)
                        .zIndex(0)
                }
                
                // Next card (right) 
                if let nextSentence = viewModel.nextSentencePreview {
                    cardView(nextSentence, showHints: false)
                        .offset(x: geometry.size.width + dragOffset)
                        .opacity(isDragging && dragOffset < 0 ? min(1.0, abs(dragOffset) / 150.0) : 0.0)
                        .zIndex(0)
                }
                
                // Current card (center)
                cardView(sentence, showHints: true)
                    .offset(x: dragOffset)
                    .zIndex(1)
            }
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
    }
    
    private func cardView(_ sentence: SentenceVM, showHints: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            sentenceCard(sentence)
            
            Spacer()
            
            if showHints {
                bottomHints(sentence)
            }
        }
    }
    
    private func sentenceCard(_ sentence: SentenceVM) -> some View {
        ZStack {
            // Back of card (English, pinyin, sound)
            if isFlipped {
                cardBackView(sentence)
            }
            
            // Front of card (Chinese only)
            if !isFlipped {
                cardFrontView(sentence)
            }
        }
        .padding(32)
        .background(cardBackground)
        .padding(.horizontal, 24)
        .onTapGesture {
            isFlipped.toggle()
        }
    }
    
    private func cardFrontView(_ sentence: SentenceVM) -> some View {
        VStack {
            Spacer()
            
            Text(sentence.hanzi)
                .font(.system(size: 36, weight: .medium, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func cardBackView(_ sentence: SentenceVM) -> some View {
        VStack(spacing: 20) {
            // Chinese text (smaller on back)
            Text(sentence.hanzi)
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Pinyin
            Text(sentence.pinyin)
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            // English translation
            Text(sentence.english)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Sound button
            Button {
                Task {
                    await viewModel.playAudio()
                }
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(25)
            }
            .padding(.top, 8)
        }
    }
    
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white.opacity(0.05))
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private func bottomHints(_ sentence: SentenceVM) -> some View {
        VStack(spacing: 8) {
            // Minimal visual hint only when user can go back
            if viewModel.canGoBack {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(.bottom, 50)
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
                isDragging = true
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let velocity = value.velocity.width
                
                if (value.translation.width > threshold || velocity > 500) && viewModel.canGoBack {
                    // Swipe right - go to previous
                    Task {
                        await viewModel.previousSentence()
                        // Immediately reset position without animation
                        resetViewsAndPosition()
                    }
                } else if value.translation.width < -threshold || velocity < -500 {
                    // Swipe left - go to next
                    Task {
                        await viewModel.nextSentence()
                        // Immediately reset position without animation
                        resetViewsAndPosition()
                    }
                } else {
                    // Return to center
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = 0
                        isDragging = false
                    }
                }
            }
    }
    
    private func resetViewsAndPosition() {
        // Immediately reset position without animation
        dragOffset = 0
        isDragging = false
        isFlipped = false
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

#Preview {
    let container = DIContainer.preview
    let viewModel = SingleSentenceViewModel(
        sentenceStore: container.sentenceStore,
        audioPlayer: container.audioPlayer,
        tts: container.tts
    )
    
    SingleSentenceView(viewModel: viewModel)
}