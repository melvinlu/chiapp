import SwiftUI
import Foundation

struct SentenceDetailView: View {
    let sentence: SentenceVM
    let isPlaying: Bool
    let context: (previous: SentenceVM?, next: SentenceVM?)
    let isSimplified: Bool
    
    let onPlayAudio: () -> Void
    let onSpeakTTS: () -> Void
    let onStopAudio: () -> Void
    
    let onRecord: () -> Void
    
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
        VStack(alignment: .leading, spacing: 16) {
            englishSection
            pinyinSection
            audioControls
        }
    }
    
    private var chineseSection: some View {
        Text(displayedHanzi)
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var pinyinSection: some View {
        Text(sentence.pinyin)
            .font(.body)
            .foregroundColor(.white)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    
    private var englishSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sentence.english)
                .font(.body)
                .foregroundColor(.white)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var audioControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                if sentence.audioURL != nil {
                    Button(action: isPlaying ? onStopAudio : onPlayAudio) {
                        Label(
                            isPlaying ? "Stop" : "Play",
                            systemImage: isPlaying ? "stop.circle.fill" : "play.circle.fill"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(false)
                } else {
                    Button(action: isPlaying ? onStopAudio : onSpeakTTS) {
                        Label(
                            isPlaying ? "Stop" : "Speak",
                            systemImage: isPlaying ? "stop.circle.fill" : "speaker.wave.2.circle.fill"
                        )
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.2, blue: 0.8),
                                    Color(red: 0.2, green: 0.1, blue: 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: openInPleco) {
                    Label("Pleco", systemImage: "book.closed.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.25, green: 0.15, blue: 0.4),
                                    Color(red: 0.15, green: 0.1, blue: 0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                
                Button(action: onRecord) {
                    Label("Record", systemImage: "mic.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.6, blue: 0.8),
                                    Color(red: 0.1, green: 0.4, blue: 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                
                if isPlaying {
                    ProgressView()
                        .scaleEffect(0.6)
                }
                
                Spacer()
            }
        }
    }
    
    private func openInPleco() {
        // Create Pleco URL scheme with the Chinese text
        let encodedText = displayedHanzi.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let plecoURL = "plecoapi://x-callback-url/s?q=\(encodedText)"
        
        if let url = URL(string: plecoURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback: Try opening Pleco app directly
                    if let appURL = URL(string: "pleco://") {
                        UIApplication.shared.open(appURL)
                    }
                }
            }
        }
    }
    
}

#Preview {
    SentenceDetailView(
        sentence: SentenceVM(
            from: SentenceEntity(
                id: "2",
                hanzi: "记得带水和防晒霜。",
                pinyin: "Jìde dài shuǐ hé fángshàishuāng.",
                english: "Remember to bring water and sunscreen.",
                packDate: Date(),
                indexInPack: 2
            )
        ),
        isPlaying: false,
        context: (
            previous: SentenceVM(
                from: SentenceEntity(
                    id: "1",
                    hanzi: "今天天气不错，我们去公园散步吧。",
                    pinyin: "Jīntiān tiānqì búcuò, wǒmen qù gōngyuán sànbù ba.",
                    english: "The weather is nice today; let's take a walk in the park.",
                    packDate: Date(),
                    indexInPack: 1
                )
            ),
            next: SentenceVM(
                from: SentenceEntity(
                    id: "3",
                    hanzi: "我们可以在湖边野餐。",
                    pinyin: "Wǒmen kěyǐ zài hú biān yěcān.",
                    english: "We can have a picnic by the lake.",
                    packDate: Date(),
                    indexInPack: 3
                )
            )
        ),
        isSimplified: true,
        onPlayAudio: {},
        onSpeakTTS: {},
        onStopAudio: {},
        onRecord: {}
    )
    .padding()
}