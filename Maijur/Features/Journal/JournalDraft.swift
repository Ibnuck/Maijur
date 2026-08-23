import Foundation

struct JournalDraft {
    var date: Date
    var text: String

    init(date: Date, text: String) {
        self.date = date
        self.text = text
    }

    init(entry: JournalEntry) {
        date = entry.date
        text = entry.text
    }

    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isDirty(comparedTo entry: JournalEntry) -> Bool {
        date != entry.date || text != entry.text
    }
}
