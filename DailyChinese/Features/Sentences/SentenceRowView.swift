import SwiftUI
import Foundation


struct SentenceRowView: View {
    let sentence: SentenceVM
    let isExpanded: Bool
    let isPlaying: Bool
    let context: (previous: SentenceVM?, next: SentenceVM?)
    let isSimplified: Bool
    
    let onTap: () -> Void
    let onPlayAudio: () -> Void
    let onSpeakTTS: () -> Void
    let onStopAudio: () -> Void
    let onRecord: () -> Void
    
    @State private var isProcessing = false
    
    private var displayedHanzi: String {
        let mutableString = NSMutableString(string: sentence.hanzi)
        if isSimplified {
            CFStringTransform(mutableString, nil, "Traditional-Simplified" as CFString, false)
        } else {
            CFStringTransform(mutableString, nil, "Simplified-Traditional" as CFString, false)
        }
        return mutableString as String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsedContent
            
            if isExpanded {
                Divider()
                    .padding(.vertical, 8)
                
                expandedContent
                    .allowsHitTesting(true)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.25),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExpanded ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand for details")
    }
    
    private var collapsedContent: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayedHanzi)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .textSelection(.enabled)
                
                statusIndicators
            }
            
            Spacer()
            
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            SentenceDetailView(
                sentence: sentence,
                isPlaying: isPlaying,
                context: context,
                isSimplified: isSimplified,
                onPlayAudio: onPlayAudio,
                onSpeakTTS: onSpeakTTS,
                onStopAudio: onStopAudio,
                onRecord: onRecord
            )
            
            actionButtons
        }
    }
    
    private var statusIndicators: some View {
        HStack(spacing: 8) {
            // Empty - no status indicators needed
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Spacer()
        }
    }
    
    private var accessibilityLabelText: String {
        return "Chinese: \(displayedHanzi)"
    }
}

#Preview("Collapsed") {
    SentenceRowView(
        sentence: SentenceVM(
            from: SentenceEntity(
                id: "1",
                hanzi: "今天天气不错，我们去公园散步吧。",
                pinyin: "Jīntiān tiānqì búcuò, wǒmen qù gōngyuán sànbù ba.",
                english: "The weather is nice today; let's take a walk in the park.",
                packDate: Date(),
                indexInPack: 1
            )
        ),
        isExpanded: false,
        isPlaying: false,
        context: (nil, nil),
        isSimplified: true,
        onTap: {},
        onPlayAudio: {},
        onSpeakTTS: {},
        onStopAudio: {},
        onRecord: {}
    )
    .padding()
}

#Preview("Expanded") {
    SentenceRowView(
        sentence: SentenceVM(
            from: SentenceEntity(
                id: "1",
                hanzi: "今天天气不错，我们去公园散步吧。",
                pinyin: "Jīntiān tiānqì búcuò, wǒmen qù gōngyuán sànbù ba.",
                english: "The weather is nice today; let's take a walk in the park.",
                packDate: Date(),
                indexInPack: 1,
                isFavorite: true
            )
        ),
        isExpanded: true,
        isPlaying: false,
        context: (nil, nil),
        isSimplified: true,
        onTap: {},
        onPlayAudio: {},
        onSpeakTTS: {},
        onStopAudio: {},
        onRecord: {}
    )
    .padding()
}