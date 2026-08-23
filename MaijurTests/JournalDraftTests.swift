import Foundation
import Testing
@testable import Maijur

@Suite("Journal draft")
struct JournalDraftTests {

    private let original = JournalEntry(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        date: Date(timeIntervalSince1970: 1_777_593_600),
        text: "A quiet morning."
    )

    @Test("Whitespace-only drafts are invalid")
    func whitespaceOnlyIsInvalid() {
        let draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: "  \n\t  "
        )

        #expect(!draft.isValid)
    }

    @Test("Meaningful drafts are valid without changing their text")
    func meaningfulTextIsValid() {
        let draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: "  Something worth remembering.  "
        )

        #expect(draft.isValid)
        #expect(draft.text == "  Something worth remembering.  ")
    }

    @Test("An unchanged draft is not dirty")
    func unchangedDraftIsNotDirty() {
        let draft = JournalDraft(entry: original)

        #expect(!draft.isDirty(comparedTo: original))
    }

    @Test("Changing the date makes a draft dirty")
    func changedDateIsDirty() {
        var draft = JournalDraft(entry: original)
        draft.date = original.date.addingTimeInterval(86_400)

        #expect(draft.isDirty(comparedTo: original))
    }

    @Test("Changing the content makes a draft dirty")
    func changedTextIsDirty() {
        var draft = JournalDraft(entry: original)
        draft.text = "A different memory."

        #expect(draft.isDirty(comparedTo: original))
    }
}
