import Foundation

struct JournalDraft {
    static let maximumCharacterCount = JournalContent.maximumCharacterCount

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
            && text.count <= Self.maximumCharacterCount
    }

    var characterCount: Int {
        text.count
    }

    var remainingCharacterCount: Int {
        max(Self.maximumCharacterCount - characterCount, 0)
    }

    var characterLimitProgress: Double {
        min(Double(characterCount) / Double(Self.maximumCharacterCount), 1)
    }

    mutating func updateText(_ proposedText: String) {
        if proposedText.count <= Self.maximumCharacterCount {
            text = proposedText
        } else if text.count <= Self.maximumCharacterCount {
            text = String(proposedText.prefix(Self.maximumCharacterCount))
        } else if proposedText.count < text.count {
            // Preserve legacy oversized entries while allowing the person to shorten them.
            text = proposedText
        }
    }

    func isDirty(comparedTo entry: JournalEntry) -> Bool {
        date != entry.date || text != entry.text
    }
}
