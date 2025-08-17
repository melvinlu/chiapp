import Foundation

struct SentenceDTO: Codable {
    let id: String
    let hanzi: String
    let pinyin: String
    let english: String
    let indexInPack: Int
    let audioAssetName: String?
    
    func toEntity(packDate: Date) -> SentenceEntity {
        var audioURL: URL?
        if let audioAssetName = audioAssetName {
            audioURL = Bundle.main.url(forResource: audioAssetName, withExtension: nil)
        }
        
        return SentenceEntity(
            id: id,
            hanzi: hanzi,
            pinyin: pinyin,
            english: english,
            packDate: packDate,
            indexInPack: indexInPack,
            audioURL: audioURL
        )
    }
}

struct DailyPackDTO: Codable {
    let date: String
    let sentences: [SentenceDTO]
    
    var packDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter.date(from: date) ?? Date()
    }
}