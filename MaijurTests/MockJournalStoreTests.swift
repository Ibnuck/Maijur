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
                summary: "Hari ini berjalan dengan baik dan terasa lebih tenang.",
                reflection: "Kamu mulai memahami hal yang paling penting dalam pengalaman ini.",
                digest: "• Ketenangan\n• Pemahaman diri",
                processingSummary: "Today went well and felt calmer.",
                processingDigest: "• Calmness\n• Self understanding",
                displayLanguageCode: "id",
                promptVersion: JournalAnalysisService.promptVersion
            )
        )
        #expect(store.history == [snapshot])

        let overall = try #require(
            store.saveOverallInsight(
                overview: "Kamu sedang membangun kebiasaan untuk memahami pengalaman sehari-hari.",
                patterns: "• Ketenangan\n• Pemahaman diri",
                recentFocus: "Perhatian terbarumu tertuju pada rasa tenang setelah melewati hari ini.",
                processingOverview: "You are building a habit of understanding everyday experiences.",
                processingPatterns: "• Calmness\n• Self understanding",
                processingRecentFocus: "Your latest focus is the calm you felt after moving through today.",
                displayLanguageCode: "id",
                coveredInsightIDs: [snapshot.id],
                promptVersion: OverallInsightService.promptVersion
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
            summary: "Jurnal pertama menceritakan hari yang terasa lebih tenang.",
            reflection: "Kamu mulai memberi ruang untuk memahami pengalaman pertamamu.",
            digest: "• Ketenangan\n• Pemahaman diri",
            processingSummary: "The first journal describes a day that felt calmer.",
            processingDigest: "• Calmness\n• Self understanding",
            displayLanguageCode: "id",
            promptVersion: JournalAnalysisService.promptVersion
        )
        let secondInsight = HistorySnapshot(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            sourceJournalID: second.id,
            sourceJournalDate: second.date,
            createdAt: second.date,
            summary: "Jurnal kedua menunjukkan perhatian pada kegiatan yang baru selesai.",
            reflection: "Kamu melihat kemajuan setelah menyelesaikan kegiatan tersebut.",
            digest: "• Kemajuan\n• Penyelesaian kegiatan",
            processingSummary: "The second journal focuses on a recently completed activity.",
            processingDigest: "• Progress\n• Completing an activity",
            displayLanguageCode: "id",
            promptVersion: JournalAnalysisService.promptVersion
        )
        let store = JournalStore(
            journals: [first, second],
            history: [secondInsight, firstInsight],
            overallInsight: OverallInsightSnapshot(
                id: UUID(),
                createdAt: first.date,
                updatedAt: first.date,
                overview: "Kamu sedang memahami perubahan dalam kegiatan sehari-hari.",
                patterns: "• Pemahaman diri",
                recentFocus: "Perhatian terbarumu tertuju pada kegiatan yang baru selesai.",
                processingOverview: "You are understanding changes in everyday activities.",
                processingPatterns: "• Self understanding",
                processingRecentFocus: "Your latest focus is the recently completed activity.",
                displayLanguageCode: "id",
                coveredInsightIDs: [firstInsight.id],
                promptVersion: OverallInsightService.promptVersion
            )
        )

        #expect(store.pendingOverallInsights.map(\.id) == [secondInsight.id])
    }

    @Test("Outdated generated insight is excluded until regenerated")
    func outdatedInsightIsExcluded() {
        let entry = journal(id: 1, timestamp: 1_700_000_000, text: "Source")
        let outdated = HistorySnapshot(
            id: UUID(),
            sourceJournalID: entry.id,
            sourceJournalDate: entry.date,
            createdAt: entry.date,
            summary: "Summary",
            reflection: "Reflection",
            digest: "Theme",
            promptVersion: "journal-insights-v4"
        )
        let store = JournalStore(journals: [entry], history: [outdated])

        #expect(store.currentJournalInsights.isEmpty)
        #expect(store.pendingOverallInsights.isEmpty)
    }

    @Test("Persistence rejects mislabeled or incomplete Indonesian output without replacing valid insight")
    func persistenceRejectsInvalidIndonesianOutput() throws {
        let entry = journal(
            id: 1,
            timestamp: 1_700_000_000,
            text: "Hari ini aku belajar memahami perasaanku dengan lebih baik."
        )
        let store = JournalStore(journals: [entry])
        let valid = try #require(
            store.saveHistory(
                for: entry.id,
                summary: "Hari ini kamu belajar memahami perasaanmu dengan lebih baik.",
                reflection: "Kamu memberi ruang untuk mengenali emosi tanpa terburu-buru menilainya.",
                digest: "• Pemahaman diri\n• Kesadaran emosi",
                processingSummary: "Today you learned to understand your feelings more clearly.",
                processingDigest: "• Self understanding\n• Emotional awareness",
                displayLanguageCode: "id",
                promptVersion: JournalAnalysisService.promptVersion
            )
        )

        let mislabeledEnglish = store.saveHistory(
            for: entry.id,
            summary: "Today was a calm and thoughtful day.",
            reflection: "You gave yourself time to understand your emotions.",
            digest: "• Self awareness\n• Calm",
            processingSummary: "Today was a calm and thoughtful day.",
            processingDigest: "• Self awareness\n• Calmness",
            displayLanguageCode: "id",
            promptVersion: JournalAnalysisService.promptVersion
        )
        let incomplete = store.saveHistory(
            for: entry.id,
            summary: "Hari ini terasa lebih tenang.",
            reflection: " ",
            digest: "• Ketenangan",
            processingSummary: "Today felt calmer.",
            processingDigest: "• Calmness",
            displayLanguageCode: "id",
            promptVersion: JournalAnalysisService.promptVersion
        )
        let validOverall = try #require(
            store.saveOverallInsight(
                overview: "Kamu sedang belajar memahami pengalaman sehari-hari dengan lebih jernih.",
                patterns: "• Pemahaman diri\n• Kesadaran emosi",
                recentFocus: "Perhatian terbarumu tertuju pada cara mengenali perasaan dengan lebih baik.",
                processingOverview: "You are learning to understand everyday experiences more clearly.",
                processingPatterns: "• Self understanding\n• Emotional awareness",
                processingRecentFocus: "Your latest focus is recognizing feelings more clearly.",
                displayLanguageCode: "id",
                coveredInsightIDs: [valid.id],
                promptVersion: OverallInsightService.promptVersion
            )
        )
        let invalidOverall = store.saveOverallInsight(
            overview: "This is still an English overview.",
            patterns: "• Self awareness",
            recentFocus: "Your recent focus is understanding emotions.",
            processingOverview: "This is still an English overview.",
            processingPatterns: "• Self awareness",
            processingRecentFocus: "Your recent focus is understanding emotions.",
            displayLanguageCode: "id",
            coveredInsightIDs: [valid.id],
            promptVersion: OverallInsightService.promptVersion
        )

        #expect(mislabeledEnglish == nil)
        #expect(incomplete == nil)
        #expect(store.history == [valid])
        #expect(invalidOverall == nil)
        #expect(store.overallInsight == validOverall)
    }

    @Test("Non-Indonesian insight is excluded until regenerated")
    func nonIndonesianInsightIsExcluded() {
        let entry = journal(id: 1, timestamp: 1_700_000_000, text: "Source")
        let englishInsight = HistorySnapshot(
            id: UUID(),
            sourceJournalID: entry.id,
            sourceJournalDate: entry.date,
            createdAt: entry.date,
            summary: "English summary",
            reflection: "English reflection",
            digest: "English theme",
            displayLanguageCode: "en",
            sourceContentHash: entry.contentHash,
            promptVersion: JournalAnalysisService.promptVersion
        )
        let store = JournalStore(journals: [entry], history: [englishInsight])

        #expect(store.currentJournalInsights.isEmpty)
        #expect(store.pendingOverallInsights.isEmpty)
    }

    @Test("Mislabeled and unversioned snapshots are excluded")
    func malformedSnapshotsAreExcluded() {
        let entry = journal(id: 1, timestamp: 1_700_000_000, text: "Source")
        let mislabeled = HistorySnapshot(
            id: UUID(),
            sourceJournalID: entry.id,
            sourceJournalDate: entry.date,
            createdAt: entry.date,
            summary: "This visible summary is still English.",
            reflection: "You can still read this reflection in English.",
            digest: "• English theme",
            processingSummary: "This processing summary is English.",
            processingDigest: "• English theme",
            displayLanguageCode: "id",
            sourceContentHash: entry.contentHash,
            promptVersion: JournalAnalysisService.promptVersion
        )
        let unversioned = HistorySnapshot(
            id: UUID(),
            sourceJournalID: entry.id,
            sourceJournalDate: entry.date,
            createdAt: entry.date,
            summary: "Jurnal ini menceritakan hari yang terasa lebih tenang.",
            reflection: "Kamu mulai memberi ruang untuk memahami pengalaman hari ini.",
            digest: "• Ketenangan\n• Pemahaman diri",
            processingSummary: "This journal describes a day that felt calmer.",
            processingDigest: "• Calmness\n• Self understanding",
            displayLanguageCode: "id",
            sourceContentHash: entry.contentHash
        )
        let malformedOverall = OverallInsightSnapshot(
            id: UUID(),
            createdAt: entry.date,
            updatedAt: entry.date,
            overview: "This overview is mislabeled as Indonesian.",
            patterns: "• English pattern",
            recentFocus: "This recent focus is still English.",
            processingOverview: "This overview is English.",
            processingPatterns: "• English pattern",
            processingRecentFocus: "This recent focus is English.",
            displayLanguageCode: "id",
            coveredInsightIDs: [],
            promptVersion: OverallInsightService.promptVersion
        )

        let store = JournalStore(
            journals: [entry],
            history: [mislabeled, unversioned],
            overallInsight: malformedOverall
        )

        #expect(store.currentJournalInsights.isEmpty)
        #expect(store.overallInsight == nil)
    }

    @Test("Editing a journal invalidates its insight and any overall synthesis that covered it")
    func editingJournalInvalidatesDerivedInsight() throws {
        let entry = journal(id: 1, timestamp: 1_700_000_000, text: "Before")
        let insight = HistorySnapshot(
            id: UUID(),
            sourceJournalID: entry.id,
            sourceJournalDate: entry.date,
            createdAt: entry.date,
            summary: "Jurnal ini menceritakan perubahan yang sedang kamu alami.",
            reflection: "Kamu mulai memahami perubahan tersebut dengan lebih tenang.",
            digest: "• Perubahan\n• Ketenangan",
            processingSummary: "This journal describes a change you are experiencing.",
            processingDigest: "• Change\n• Calmness",
            displayLanguageCode: "id",
            sourceContentHash: entry.contentHash,
            promptVersion: JournalAnalysisService.promptVersion
        )
        let store = JournalStore(
            journals: [entry],
            history: [insight],
            overallInsight: OverallInsightSnapshot(
                id: UUID(),
                createdAt: entry.date,
                updatedAt: entry.date,
                overview: "Kamu sedang memahami perubahan dalam pengalaman sehari-hari.",
                patterns: "• Pemahaman diri",
                recentFocus: "Perhatian terbarumu tertuju pada perubahan yang sedang berlangsung.",
                processingOverview: "You are understanding changes in everyday experiences.",
                processingPatterns: "• Self understanding",
                processingRecentFocus: "Your latest focus is the change currently taking place.",
                displayLanguageCode: "id",
                coveredInsightIDs: [insight.id],
                promptVersion: OverallInsightService.promptVersion
            )
        )

        let updated = store.updateJournal(id: entry.id, date: entry.date, text: "After")

        #expect(updated != nil)
        #expect(store.history.isEmpty)
        #expect(store.overallInsight == nil)
    }

    @Test("Current insight lookup stays correct for a long journal collection")
    func currentInsightsForLongCollection() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let journals = (0..<1_000).map { index in
            JournalEntry(
                id: UUID(),
                date: baseDate.addingTimeInterval(TimeInterval(index)),
                text: "Journal \(index)"
            )
        }
        let history = journals.map { entry in
            HistorySnapshot(
                id: UUID(),
                sourceJournalID: entry.id,
                sourceJournalDate: entry.date,
                createdAt: entry.date,
                summary: "Jurnal ini mencatat kegiatan dan perasaan pada hari tersebut.",
                reflection: "Kamu memberi perhatian pada pengalaman yang terjadi hari itu.",
                digest: "• Kegiatan harian\n• Kesadaran emosi",
                processingSummary: "This journal records activities and feelings from that day.",
                processingDigest: "• Daily activities\n• Emotional awareness",
                displayLanguageCode: "id",
                sourceContentHash: entry.contentHash,
                promptVersion: JournalAnalysisService.promptVersion
            )
        }
        let store = JournalStore(journals: journals, history: history)

        #expect(store.currentJournalInsights.count == 1_000)
        #expect(store.currentJournalInsights.map(\.sourceJournalDate) == journals.map(\.date).sorted())
    }

    private func journal(id: UInt8, timestamp: TimeInterval, text: String) -> JournalEntry {
        JournalEntry(
            id: UUID(uuid: (id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
            date: Date(timeIntervalSince1970: timestamp),
            text: text
        )
    }
}
