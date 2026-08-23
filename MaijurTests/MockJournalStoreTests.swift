import Foundation
import Testing
@testable import Maijur

@Suite("Mock journal store")
@MainActor
struct MockJournalStoreTests {

    @Test("Journals are exposed newest first")
    func journalsAreNewestFirst() {
        let older = journal(id: 1, timestamp: 1_700_000_000, text: "Older")
        let newer = journal(id: 2, timestamp: 1_800_000_000, text: "Newer")
        let store = MockJournalStore(journals: [older, newer])

        #expect(store.journals.map(\.id) == [newer.id, older.id])
    }

    @Test("Creating rejects whitespace-only text")
    func creatingWhitespaceOnlyTextFails() {
        let store = MockJournalStore()

        let created = store.createJournal(
            date: Date(timeIntervalSince1970: 1_800_000_000),
            text: " \n\t "
        )

        #expect(created == nil)
        #expect(store.journals.isEmpty)
    }

    @Test("Creating preserves meaningful text")
    func creatingPreservesMeaningfulText() throws {
        let store = MockJournalStore()
        let text = "  A meaningful entry.  "

        let created = try #require(
            store.createJournal(
                date: Date(timeIntervalSince1970: 1_800_000_000),
                text: text
            )
        )

        #expect(created.text == text)
        #expect(store.journals.first?.text == text)
    }

    @Test("Updating keeps the identifier and changes date and text")
    func updatingKeepsIdentifier() throws {
        let original = journal(id: 1, timestamp: 1_700_000_000, text: "Before")
        let store = MockJournalStore(journals: [original])
        let newDate = Date(timeIntervalSince1970: 1_800_000_000)

        let updated = try #require(
            store.updateJournal(
                id: original.id,
                date: newDate,
                text: "After"
            )
        )

        #expect(updated.id == original.id)
        #expect(updated.date == newDate)
        #expect(updated.text == "After")
        #expect(store.journals == [updated])
    }

    @Test("Deleting removes only the selected journal")
    func deletingRemovesOnlySelectedJournal() {
        let first = journal(id: 1, timestamp: 1_700_000_000, text: "First")
        let second = journal(id: 2, timestamp: 1_800_000_000, text: "Second")
        let store = MockJournalStore(journals: [first, second])

        store.deleteJournal(id: second.id)

        #expect(store.journals == [first])
    }

    @Test("Deleting a journal preserves its History snapshot")
    func deletingJournalPreservesHistory() {
        let entry = journal(id: 1, timestamp: 1_700_000_000, text: "Source")
        let snapshot = HistorySnapshot(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            sourceJournalID: entry.id,
            sourceJournalDate: entry.date,
            createdAt: Date(timeIntervalSince1970: 1_700_003_600),
            summary: "Summary",
            reflection: "Reflection",
            digest: "Digest"
        )
        let store = MockJournalStore(journals: [entry], history: [snapshot])

        store.deleteJournal(id: entry.id)

        #expect(store.journals.isEmpty)
        #expect(store.history == [snapshot])
    }

    private func journal(id: UInt8, timestamp: TimeInterval, text: String) -> JournalEntry {
        JournalEntry(
            id: UUID(uuid: (id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
            date: Date(timeIntervalSince1970: timestamp),
            text: text
        )
    }
}
