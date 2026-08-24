import Foundation

struct HistorySnapshot: Equatable, Identifiable {
    let id: UUID
    let sourceJournalID: UUID
    let sourceJournalDate: Date
    let createdAt: Date
    let summary: String
    let reflection: String
    let digest: String
    let sourceContentHash: String
    let promptVersion: String

    init(
        id: UUID,
        sourceJournalID: UUID,
        sourceJournalDate: Date,
        createdAt: Date,
        summary: String,
        reflection: String,
        digest: String,
        sourceContentHash: String = "",
        promptVersion: String = ""
    ) {
        self.id = id
        self.sourceJournalID = sourceJournalID
        self.sourceJournalDate = sourceJournalDate
        self.createdAt = createdAt
        self.summary = summary
        self.reflection = reflection
        self.digest = digest
        self.sourceContentHash = sourceContentHash
        self.promptVersion = promptVersion
    }

    func belongsToCurrentRevision(of journal: JournalEntry) -> Bool {
        sourceJournalID == journal.id && (sourceContentHash.isEmpty || sourceContentHash == journal.contentHash)
    }

    func isCompatible(with currentPromptVersion: String) -> Bool {
        promptVersion.isEmpty || promptVersion == currentPromptVersion
    }
}
