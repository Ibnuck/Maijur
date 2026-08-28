import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class JournalStore {
    private let modelContext: ModelContext?
    private(set) var journals: [JournalEntry]
    private(set) var history: [HistorySnapshot]
    private(set) var overallInsight: OverallInsightSnapshot?
    var journalsPhase: LoadPhase
    var historyPhase: LoadPhase
    var insightLoadingJournalIDs: Set<UUID>
    private(set) var persistenceError: String?

    init(
        journals: [JournalEntry] = [],
        history: [HistorySnapshot] = [],
        overallInsight: OverallInsightSnapshot? = nil,
        journalsPhase: LoadPhase = .loaded,
        historyPhase: LoadPhase = .loaded,
        insightLoadingJournalIDs: Set<UUID> = [],
        persistenceError: String? = nil
    ) {
        modelContext = nil
        self.journals = journals.sorted { $0.date > $1.date }
        self.history = history
        self.overallInsight = overallInsight
        self.journalsPhase = journalsPhase
        self.historyPhase = historyPhase
        self.insightLoadingJournalIDs = insightLoadingJournalIDs
        self.persistenceError = persistenceError
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        journals = []
        history = []
        overallInsight = nil
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

    var currentJournalInsights: [HistorySnapshot] {
        let journalsByID = journals.reduce(into: [UUID: JournalEntry]()) { result, journal in
            result[journal.id] = journal
        }
        var seenJournalIDs = Set<UUID>()
        return history
            .filter { snapshot in
                guard let journal = journalsByID[snapshot.sourceJournalID],
                      snapshot.belongsToCurrentRevision(of: journal),
                      snapshot.isCompatible(with: JournalAnalysisService.promptVersion),
                      seenJournalIDs.insert(snapshot.sourceJournalID).inserted
                else { return false }
                return true
            }
            .sorted { $0.sourceJournalDate < $1.sourceJournalDate }
    }

    var pendingOverallInsights: [HistorySnapshot] {
        let coveredIDs = Set(overallInsight?.coveredInsightIDs ?? [])
        return currentJournalInsights.filter { !coveredIDs.contains($0.id) }
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
            let removedIDs = history.filter { $0.sourceJournalID == id }.map(\.id)
            history.removeAll { $0.sourceJournalID == id }
            resetOverallInsightIfCovering(removedIDs)
            sortJournals()
            return entry
        }

        do {
            let descriptor = FetchDescriptor<StoredJournal>(predicate: #Predicate { $0.id == id })
            guard let record = try modelContext.fetch(descriptor).first else { return nil }
            try removeInsights(for: id)
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
            let removedIDs = history.filter { $0.sourceJournalID == id }.map(\.id)
            history.removeAll { $0.sourceJournalID == id }
            resetOverallInsightIfCovering(removedIDs)
            return true
        }

        do {
            let journalDescriptor = FetchDescriptor<StoredJournal>(predicate: #Predicate { $0.id == id })
            try removeInsights(for: id)
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
        processingSummary: String? = nil,
        processingDigest: String? = nil,
        sourceLanguageCode: String = "en",
        displayLanguageCode: String = "en",
        coveredJournalIDs: [UUID] = [],
        promptVersion: String = "",
        modelVersion: String = ""
    ) -> HistorySnapshot? {
        guard let journal = journals.first(where: { $0.id == journalID }) else { return nil }
        guard let modelContext else {
            let removedIDs = history.filter { $0.sourceJournalID == journalID }.map(\.id)
            history.removeAll { $0.sourceJournalID == journalID }
            resetOverallInsightIfCovering(removedIDs)
            let snapshot = HistorySnapshot(
                id: UUID(),
                sourceJournalID: journal.id,
                sourceJournalDate: journal.date,
                createdAt: .now,
                summary: summary,
                reflection: reflection,
                digest: digest,
                processingSummary: processingSummary,
                processingDigest: processingDigest,
                sourceLanguageCode: sourceLanguageCode,
                displayLanguageCode: displayLanguageCode,
                sourceContentHash: journal.contentHash,
                promptVersion: promptVersion
            )
            history.insert(snapshot, at: 0)
            return snapshot
        }

        do {
            let descriptor = FetchDescriptor<StoredJournal>(predicate: #Predicate { $0.id == journalID })
            guard let journal = try modelContext.fetch(descriptor).first else { return nil }
            try removeInsights(for: journalID)
            let record = StoredHistorySnapshot(
                sourceJournalID: journal.id,
                sourceJournalDate: journal.journalDate,
                sourceRevision: journal.revision,
                sourceContentHash: journal.contentHash,
                summary: summary,
                reflection: reflection,
                digest: digest,
                processingSummary: processingSummary,
                processingDigest: processingDigest,
                sourceLanguageCode: sourceLanguageCode,
                displayLanguageCode: displayLanguageCode,
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

    @discardableResult
    func saveOverallInsight(
        overview: String,
        patterns: String,
        recentFocus: String,
        processingOverview: String? = nil,
        processingPatterns: String? = nil,
        processingRecentFocus: String? = nil,
        displayLanguageCode: String = "id",
        coveredInsightIDs: [UUID],
        promptVersion: String = "",
        modelVersion: String = ""
    ) -> OverallInsightSnapshot? {
        let createdAt = overallInsight?.createdAt ?? .now
        let snapshot = OverallInsightSnapshot(
            id: UUID(),
            createdAt: createdAt,
            updatedAt: .now,
            overview: overview,
            patterns: patterns,
            recentFocus: recentFocus,
            processingOverview: processingOverview,
            processingPatterns: processingPatterns,
            processingRecentFocus: processingRecentFocus,
            displayLanguageCode: displayLanguageCode,
            coveredInsightIDs: coveredInsightIDs,
            promptVersion: promptVersion
        )

        guard let modelContext else {
            overallInsight = snapshot
            return snapshot
        }

        do {
            try modelContext.fetch(FetchDescriptor<StoredOverallInsight>()).forEach(modelContext.delete)
            let record = StoredOverallInsight(
                createdAt: createdAt,
                overview: overview,
                patterns: patterns,
                recentFocus: recentFocus,
                processingOverview: processingOverview,
                processingPatterns: processingPatterns,
                processingRecentFocus: processingRecentFocus,
                displayLanguageCode: displayLanguageCode,
                coveredInsightIDs: coveredInsightIDs,
                promptVersion: promptVersion,
                modelVersion: modelVersion
            )
            modelContext.insert(record)
            guard saveChanges() else { return nil }
            reload()
            return record.snapshot
        } catch {
            persistenceError = "Insight keseluruhan tidak dapat disimpan. Silakan coba lagi."
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
            let overallDescriptor = FetchDescriptor<StoredOverallInsight>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            journals = try modelContext.fetch(journalDescriptor).map(\.entry)
            history = try modelContext.fetch(historyDescriptor).map(\.snapshot)
            let storedOverallInsight = try modelContext.fetch(overallDescriptor).first?.snapshot
            overallInsight = storedOverallInsight?.isCompatible(with: OverallInsightService.promptVersion) == true
                ? storedOverallInsight
                : nil
            journalsPhase = .loaded
            historyPhase = .loaded
            persistenceError = nil
        } catch {
            journals = []
            history = []
            overallInsight = nil
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

    private func removeInsights(for journalID: UUID) throws {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<StoredHistorySnapshot>(predicate: #Predicate { $0.sourceJournalID == journalID })
        let records = try modelContext.fetch(descriptor)
        resetOverallInsightIfCovering(records.map(\.id))
        records.forEach(modelContext.delete)
    }

    private func resetOverallInsightIfCovering(_ insightIDs: [UUID]) {
        guard let overallInsight,
              !Set(overallInsight.coveredInsightIDs).isDisjoint(with: insightIDs)
        else { return }

        self.overallInsight = nil
        guard let modelContext else { return }
        if let records = try? modelContext.fetch(FetchDescriptor<StoredOverallInsight>()) {
            records.forEach(modelContext.delete)
        }
    }

}
