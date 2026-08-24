import Foundation

struct JournalEntry: Equatable, Hashable, Identifiable {
    let id: UUID
    let date: Date
    let text: String

    var contentHash: String {
        JournalContent.hash(text)
    }
}

enum JournalContent {
    static let maximumCharacterCount = 2_400

    static func hash(_ content: String) -> String {
        content.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        .description
    }
}
