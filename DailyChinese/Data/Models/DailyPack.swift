import Foundation

struct DailyPack {
    let date: Date
    let sentences: [SentenceEntity]
    
    init(date: Date, sentences: [SentenceEntity]) {
        self.date = date
        self.sentences = sentences.sorted { $0.indexInPack < $1.indexInPack }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}