import Foundation
import SwiftData

@Model
final class SentenceEntity {
    @Attribute(.unique) var id: String
    var hanzi: String
    var pinyin: String
    var english: String
    var packDate: Date
    var indexInPack: Int
    var audioURL: URL?
    var isLearned: Bool
    var isFavorite: Bool
    var createdAt: Date?
    var batchId: String?
    
    init(
        id: String,
        hanzi: String,
        pinyin: String,
        english: String,
        packDate: Date,
        indexInPack: Int,
        audioURL: URL? = nil,
        isLearned: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date? = Date(),
        batchId: String? = nil
    ) {
        self.id = id
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.english = english
        self.packDate = packDate
        self.indexInPack = indexInPack
        self.audioURL = audioURL
        self.isLearned = isLearned
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.batchId = batchId
    }
}

struct SentenceVM: Identifiable, Equatable {
    let id: String
    let hanzi: String
    let pinyin: String
    let english: String
    let packDate: Date
    let indexInPack: Int
    let audioURL: URL?
    let isLearned: Bool
    let isFavorite: Bool
    let createdAt: Date?
    let batchId: String?
    
    init(from entity: SentenceEntity) {
        self.id = entity.id
        self.hanzi = entity.hanzi
        self.pinyin = entity.pinyin
        self.english = entity.english
        self.packDate = entity.packDate
        self.indexInPack = entity.indexInPack
        self.audioURL = entity.audioURL
        self.isLearned = entity.isLearned
        self.isFavorite = entity.isFavorite
        self.createdAt = entity.createdAt
        self.batchId = entity.batchId
    }
}