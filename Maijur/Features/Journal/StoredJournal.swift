import Foundation
import SwiftData

@Model
final class StoredJournal {
    @Attribute(.unique) var id: UUID
    var journalDate: Date
    var createdAt: Date
    var updatedAt: Date
    var content: String
    var revision: Int
    var contentHash: String

    init(
        id: UUID = UUID(),
        journalDate: Date,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        content: String,
        revision: Int = 1,
        contentHash: String
    ) {
        self.id = id
        self.journalDate = journalDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.content = content
        self.revision = revision
        self.contentHash = contentHash
    }

    var entry: JournalEntry {
        JournalEntry(id: id, date: journalDate, text: content)
    }
}
