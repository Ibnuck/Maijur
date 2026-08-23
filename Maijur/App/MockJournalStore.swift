import Foundation
import Observation

@Observable
@MainActor
final class MockJournalStore {
    private(set) var journals: [JournalEntry]
    private(set) var history: [HistorySnapshot]
    var journalsPhase: LoadPhase
    var historyPhase: LoadPhase
    var insightLoadingJournalIDs: Set<UUID>

    init(
        journals: [JournalEntry] = [],
        history: [HistorySnapshot] = [],
        journalsPhase: LoadPhase = .loaded,
        historyPhase: LoadPhase = .loaded,
        insightLoadingJournalIDs: Set<UUID> = []
    ) {
        self.journals = journals.sorted { $0.date > $1.date }
        self.history = history
        self.journalsPhase = journalsPhase
        self.historyPhase = historyPhase
        self.insightLoadingJournalIDs = insightLoadingJournalIDs
    }

    @discardableResult
    func createJournal(date: Date, text: String) -> JournalEntry? {
        let draft = JournalDraft(date: date, text: text)
        guard draft.isValid else { return nil }

        let entry = JournalEntry(id: UUID(), date: date, text: text)
        journals.append(entry)
        sortJournals()
        return entry
    }

    @discardableResult
    func updateJournal(id: UUID, date: Date, text: String) -> JournalEntry? {
        let draft = JournalDraft(date: date, text: text)
        guard draft.isValid,
              let index = journals.firstIndex(where: { $0.id == id })
        else { return nil }

        let entry = JournalEntry(id: id, date: date, text: text)
        journals[index] = entry
        sortJournals()
        return entry
    }

    func deleteJournal(id: UUID) {
        journals.removeAll { $0.id == id }
    }

    private func sortJournals() {
        journals.sort { $0.date > $1.date }
    }
}
