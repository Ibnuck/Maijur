import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class JournalStore {
    private let modelContext: ModelContext?
    private(set) var journals: [JournalEntry]
    private(set) var history: [HistorySnapshot]
    var journalsPhase: LoadPhase
    var historyPhase: LoadPhase
    var insightLoadingJournalIDs: Set<UUID>
    private(set) var persistenceError: String?

    init(
        journals: [JournalEntry] = [],
        history: [HistorySnapshot] = [],
        journalsPhase: LoadPhase = .loaded,
        historyPhase: LoadPhase = .loaded,
        insightLoadingJournalIDs: Set<UUID> = [],
        persistenceError: String? = nil
    ) {
        modelContext = nil
        self.journals = journals.sorted { $0.date > $1.date }
        self.history = history
        self.journalsPhase = journalsPhase
        self.historyPhase = historyPhase
        self.insightLoadingJournalIDs = insightLoadingJournalIDs
        self.persistenceError = persistenceError
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        journals = []
        history = []
        journalsPhase = .loading
        historyPhase = .loading
        insightLoadingJournalIDs = []
        persistenceError = nil
        reload()
    }

    static func unavailable(message: String) -> JournalStore {
        JournalStore(persistenceError: message)
    }

    func clearPersistenceError() {
        persistenceError = nil
    }

    @discardableResult
    func createJournal(date: Date, text: String) -> JournalEntry? {
        let draft = JournalDraft(date: date, text: text)
        guard draft.isValid else { return nil }

        guard let modelContext else {
            let entry = JournalEntry(id: UUID(), date: date, text: text)
            journals.append(entry)
            sortJournals()
            return entry
        }

        let entry = JournalEntry(id: UUID(), date: date, text: text)
        let record = StoredJournal(
            id: entry.id,
            journalDate: entry.date,
            content: entry.text,
            contentHash: JournalContent.hash(entry.text)
        )
        modelContext.insert(record)
        guard saveChanges() else { return nil }
        reload()
        return entry
    }

    @discardableResult
    func updateJournal(id: UUID, date: Date, text: String) -> JournalEntry? {
        let draft = JournalDraft(date: date, text: text)
        guard draft.isValid,
              let index = journals.firstIndex(where: { $0.id == id })
        else { return nil }

        let entry = JournalEntry(id: id, date: date, text: text)
        guard let modelContext else {
            journals[index] = entry
            sortJournals()
            return entry
        }

        do {
            let descriptor = FetchDescriptor<StoredJournal>(predicate: #Predicate { $0.id == id })
            guard let record = try modelContext.fetch(descriptor).first else { return nil }
            record.journalDate = date
            record.content = text
            record.updatedAt = .now
            record.revision += 1
            record.contentHash = JournalContent.hash(text)
            guard saveChanges() else { return nil }
            reload()
            return entry
        } catch {
            persistenceError = "Jurnal tidak dapat diperbarui. Silakan coba lagi."
            return nil
        }
    }

    @discardableResult
    func deleteJournal(id: UUID) -> Bool {
        guard let modelContext else {
            journals.removeAll { $0.id == id }
            history.removeAll { $0.sourceJournalID == id }
            return true
        }

        do {
            let journalDescriptor = FetchDescriptor<StoredJournal>(predicate: #Predicate { $0.id == id })
            let historyDescriptor = FetchDescriptor<StoredHistorySnapshot>(predicate: #Predicate { $0.sourceJournalID == id })
            try modelContext.fetch(historyDescriptor).forEach(modelContext.delete)
            try modelContext.fetch(journalDescriptor).forEach(modelContext.delete)
            guard saveChanges() else { return false }
            reload()
            return true
        } catch {
            persistenceError = "Jurnal tidak dapat dihapus. Silakan coba lagi."
            return false
        }
    }

    @discardableResult
    func saveHistory(
        for journalID: UUID,
        summary: String,
        reflection: String,
        digest: String,
        coveredJournalIDs: [UUID] = [],
        promptVersion: String = "",
        modelVersion: String = ""
    ) -> HistorySnapshot? {
        guard let modelContext else { return nil }

        do {
            let descriptor = FetchDescriptor<StoredJournal>(predicate: #Predicate { $0.id == journalID })
            guard let journal = try modelContext.fetch(descriptor).first else { return nil }
            let record = StoredHistorySnapshot(
                sourceJournalID: journal.id,
                sourceJournalDate: journal.journalDate,
                sourceRevision: journal.revision,
                sourceContentHash: journal.contentHash,
                summary: summary,
                reflection: reflection,
                digest: digest,
                coveredJournalIDs: coveredJournalIDs,
                promptVersion: promptVersion,
                modelVersion: modelVersion
            )
            modelContext.insert(record)
            guard saveChanges() else { return nil }
            reload()
            return record.snapshot
        } catch {
            persistenceError = "Insight tidak dapat disimpan. Silakan coba lagi."
            return nil
        }
    }

    private func reload() {
        guard let modelContext else { return }

        do {
            let journalDescriptor = FetchDescriptor<StoredJournal>(
                sortBy: [
                    SortDescriptor(\.journalDate, order: .reverse),
                    SortDescriptor(\.createdAt, order: .reverse)
                ]
            )
            let historyDescriptor = FetchDescriptor<StoredHistorySnapshot>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            journals = try modelContext.fetch(journalDescriptor).map(\.entry)
            history = try modelContext.fetch(historyDescriptor).map(\.snapshot)
            journalsPhase = .loaded
            historyPhase = .loaded
            persistenceError = nil
        } catch {
            journals = []
            history = []
            journalsPhase = .loaded
            historyPhase = .loaded
            persistenceError = "MaiJur tidak dapat membuka penyimpanan lokal. Jurnal baru tetap terbuka sampai kamu mencoba lagi."
        }
    }

    private func saveChanges() -> Bool {
        guard let modelContext else { return true }

        do {
            try modelContext.save()
            persistenceError = nil
            return true
        } catch {
            modelContext.rollback()
            persistenceError = "MaiJur tidak dapat menyimpan perubahan ini. Silakan coba lagi."
            return false
        }
    }

    private func sortJournals() {
        journals.sort { $0.date > $1.date }
    }

}
