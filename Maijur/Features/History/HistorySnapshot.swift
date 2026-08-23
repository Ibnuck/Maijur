import Foundation

struct HistorySnapshot: Equatable, Identifiable {
    let id: UUID
    let sourceJournalID: UUID
    let sourceJournalDate: Date
    let createdAt: Date
    let summary: String
    let reflection: String
    let digest: String
}
