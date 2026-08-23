import Foundation

struct JournalEntry: Equatable, Identifiable {
    let id: UUID
    let date: Date
    let text: String
}
