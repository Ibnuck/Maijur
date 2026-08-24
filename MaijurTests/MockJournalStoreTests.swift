import Foundation
import SwiftData
import Testing
@testable import Maijur

@Suite("Journal store")
@MainActor
struct JournalStoreTests {

    @Test("Journals are exposed newest first")
    func journalsAreNewestFirst() {
        let older = journal(id: 1, timestamp: 1_700_000_000, text: "Older")
        let newer = journal(id: 2, timestamp: 1_800_000_000, text: "Newer")
        let store = JournalStore(journals: [older, newer])

        #expect(store.journals.map(\.id) == [newer.id, older.id])
    }

    @Test("Creating rejects whitespace-only text")
    func creatingWhitespaceOnlyTextFails() {
        let store = JournalStore()

        let created = store.createJournal(
            date: Date(timeIntervalSince1970: 1_800_000_000),
            text: " \n\t "
        )

        #expect(created == nil)
        #expect(store.journals.isEmpty)
    }

    @Test("Creating preserves meaningful text")
    func creatingPreservesMeaningfulText() throws {
        let store = JournalStore()
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
        let store = JournalStore(journals: [original])
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
        let store = JournalStore(journals: [first, second])

        store.deleteJournal(id: second.id)

        #expect(store.journals == [first])
    }

    @Test("Deleting a journal removes its private History snapshot")
    func deletingJournalRemovesDerivedHistory() {
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
        let store = JournalStore(journals: [entry], history: [snapshot])

        store.deleteJournal(id: entry.id)

        #expect(store.journals.isEmpty)
        #expect(store.history.isEmpty)
    }

    @Test("Local store keeps journals and removes derived insights")
    func localStorePersistsJournalAndCleansUpHistory() throws {
        let container = try ModelContainer(
            for: StoredJournal.self,
            StoredHistorySnapshot.self,
            StoredOverallInsight.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = JournalStore(modelContext: container.mainContext)
        let journal = try #require(
            store.createJournal(
                date: Date(timeIntervalSince1970: 1_800_000_000),
                text: "A locally saved entry"
            )
        )

        let secondStore = JournalStore(modelContext: container.mainContext)
        #expect(secondStore.journals == [journal])

        let snapshot = try #require(
            store.saveHistory(
                for: journal.id,
                summary: "Summary",
                reflection: "Reflection",
                digest: "Digest"
            )
        )
        #expect(store.history == [snapshot])

        let overall = try #require(
            store.saveOverallInsight(
                overview: "Overview",
                patterns: "Patterns",
                recentFocus: "Recent focus",
                coveredInsightIDs: [snapshot.id]
            )
        )
        let reloadedStore = JournalStore(modelContext: container.mainContext)
        #expect(reloadedStore.overallInsight == overall)
        #expect(reloadedStore.pendingOverallInsights.isEmpty)

        #expect(store.deleteJournal(id: journal.id))
        #expect(store.journals.isEmpty)
        #expect(store.history.isEmpty)
        #expect(store.overallInsight == nil)
    }

    @Test("Overall insight only receives per-journal insights not covered before")
    func overallInsightTracksIncrementalCoverage() throws {
        let first = journal(id: 1, timestamp: 1_700_000_000, text: "First")
        let second = journal(id: 2, timestamp: 1_800_000_000, text: "Second")
        let firstInsight = HistorySnapshot(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            sourceJournalID: first.id,
            sourceJournalDate: first.date,
            createdAt: first.date,
            summary: "First summary",
            reflection: "First reflection",
            digest: "First theme"
        )
        let secondInsight = HistorySnapshot(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            sourceJournalID: second.id,
            sourceJournalDate: second.date,
            createdAt: second.date,
            summary: "Second summary",
            reflection: "Second reflection",
            digest: "Second theme"
        )
        let store = JournalStore(
            journals: [first, second],
            history: [secondInsight, firstInsight],
            overallInsight: OverallInsightSnapshot(
                id: UUID(),
                createdAt: first.date,
                updatedAt: first.date,
                overview: "Overview",
                patterns: "Patterns",
                recentFocus: "Recent",
                coveredInsightIDs: [firstInsight.id]
            )
        )

        #expect(store.pendingOverallInsights.map(\.id) == [secondInsight.id])
    }

    private func journal(id: UInt8, timestamp: TimeInterval, text: String) -> JournalEntry {
        JournalEntry(
            id: UUID(uuid: (id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
            date: Date(timeIntervalSince1970: timestamp),
            text: text
        )
    }
}
