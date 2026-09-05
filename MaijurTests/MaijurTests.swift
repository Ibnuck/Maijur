//
//  MaijurTests.swift
//  MaijurTests
//
//  Created by Ibnu Taufick Ahraza on 8/23/26.
//

import Foundation
import Testing
@testable import Maijur

@Suite("Deterministic mock data")
@MainActor
struct MaijurTests {

    @Test("Populated fixtures are repeatable and loaded")
    func populatedFixturesAreDeterministic() {
        let first = MockData.populatedStore()
        let second = MockData.populatedStore()

        #expect(first.journalsPhase == .loaded)
        #expect(first.historyPhase == .loaded)
        #expect(!first.journals.isEmpty)
        #expect(!first.history.isEmpty)
        #expect(first.journals == second.journals)
        #expect(first.history == second.history)
        #expect(first.history.allSatisfy {
            $0.isDisplayed(in: InsightLanguagePipeline.displayLanguage)
        })
        #expect(first.history.allSatisfy { !$0.processingSummary.isEmpty })
        #expect(first.insightLoadingJournalIDs.isEmpty)
    }

    @Test("Insight pipeline processes in English and displays in Indonesian")
    func insightLanguageContract() {
        let englishPlan = InsightLanguagePipeline.journalPlan(
            for: "Today I walked home after the rain and felt calm while thinking about my week."
        )
        let indonesianPlan = InsightLanguagePipeline.journalPlan(
            for: "Hari ini aku berjalan pulang setelah hujan dan merasa tenang saat memikirkan kegiatanku minggu ini."
        )

        #expect(InsightLanguagePipeline.processingLanguage.minimalIdentifier == "en")
        #expect(InsightLanguagePipeline.displayLanguage.minimalIdentifier == "id")
        #expect(englishPlan.sourceLanguage?.isEquivalent(to: Locale.Language(identifier: "en")) == true)
        #expect(englishPlan.needsInputTranslation == false)
        #expect(indonesianPlan.sourceLanguage?.isEquivalent(to: Locale.Language(identifier: "id")) == true)
        #expect(indonesianPlan.needsInputTranslation == true)
        #expect(InsightLanguagePipeline.isValidJournalDisplay(
            summary: "Hari ini terasa lebih ringan setelah kamu menyelesaikan pekerjaan.",
            reflection: "Kamu memberi dirimu waktu untuk memahami pengalaman tersebut.",
            digest: "• Ketenangan\n• Penyelesaian pekerjaan"
        ))
        #expect(!InsightLanguagePipeline.isValidJournalDisplay(
            summary: "Today felt calmer after you finished the work.",
            reflection: "You gave yourself time to understand the experience.",
            digest: "• Calm\n• Finishing work"
        ))
        #expect(!InsightLanguagePipeline.isValidJournalDisplay(
            summary: "Hari ini terasa lebih ringan.",
            reflection: " ",
            digest: "• Ketenangan"
        ))
        #expect(!InsightLanguagePipeline.isValidJournalDisplay(
            summary: "Today felt calmer after completing the work.",
            reflection: "Kamu memberi dirimu waktu yang cukup panjang untuk memahami pengalaman dan perasaanmu hari ini.",
            digest: "• Ketenangan\n• Penyelesaian pekerjaan"
        ))
        #expect(InsightLanguagePipeline.isValidJournalProcessing(
            summary: "Today felt calmer after you finished the work.",
            reflection: "You gave yourself time to understand the experience.",
            digest: "• Calmness\n• Finishing work"
        ))
        #expect(!InsightLanguagePipeline.isValidJournalProcessing(
            summary: "Hari ini terasa lebih ringan setelah pekerjaan selesai.",
            reflection: "Kamu memberi dirimu waktu untuk memahami pengalaman itu.",
            digest: "• Ketenangan\n• Penyelesaian pekerjaan"
        ))
    }

    @Test("Random Latin text is rejected as an uncertain source language")
    func randomLatinTextIsRejected() {
        let plan = InsightLanguagePipeline.journalPlan(
            for: "dabksfybd aigefb7e983 ASJDHF Soto aiw8e77"
        )

        #expect(plan.sourceLanguage == nil)
        #expect(plan.confidence == nil)
        #expect(plan.needsInputTranslation == false)
    }

    @Test("Short English with a clear language margin remains supported")
    func shortEnglishWithClearMarginIsSupported() {
        let plan = InsightLanguagePipeline.journalPlan(for: "I eat shit today")

        #expect(plan.sourceLanguage?.isEquivalent(to: Locale.Language(identifier: "en")) == true)
        #expect(plan.confidence != nil)
        #expect(plan.needsInputTranslation == false)
    }

    @Test("Natural Indonesian and English code mixing remains supported")
    func indonesianEnglishMixIsSupported() {
        let plan = InsightLanguagePipeline.journalPlan(
            for: "Hari ini aku meeting dengan team lalu makan fried rice bersama teman."
        )

        #expect(plan.sourceLanguage?.isEquivalent(to: Locale.Language(identifier: "id")) == true)
        #expect(plan.needsInputTranslation)
    }

    @Test("A translation that drops most source words is rejected")
    func incompleteTranslationCoverageIsRejected() {
        #expect(!InsightLanguagePipeline.hasPlausibleTranslationCoverage(
            sourceText: "Kumakain ako ng fried rice sa gilid ng bangin habang pinagmamasdan ang kagubatan mula sa bundok.",
            translatedText: "fried rice"
        ))
        #expect(InsightLanguagePipeline.hasPlausibleTranslationCoverage(
            sourceText: "Hari ini aku makan nasi goreng bersama teman setelah pulang bekerja.",
            translatedText: "Today I ate fried rice with a friend after coming home from work."
        ))
    }

    @Test("Short translated English trusts Translation target metadata")
    func shortTranslatedEnglishUsesReportedTargetLanguage() {
        let translatedSatay = "Eating chicken satay at Madura stall with Ibnu."

        #expect(InsightLanguagePipeline.isValidTranslatedInput(
            translatedSatay,
            reportedTargetLanguage: Locale.Language(identifier: "en")
        ))
        #expect(!InsightLanguagePipeline.isValidTranslatedInput(
            translatedSatay,
            reportedTargetLanguage: Locale.Language(identifier: "id")
        ))
    }

    @Test("Calendar metadata is removed from journal themes")
    func calendarMetadataIsRemovedFromThemes() {
        let themes = JournalThemeSanitizer.sanitize([
            "August 31, 2026",
            "Date",
            "Chicken satay",
            "Friendship"
        ])

        #expect(themes == ["Chicken satay", "Friendship"])
    }

    @Test("Empty fixture has loaded empty lists")
    func emptyFixture() {
        let store = MockData.emptyStore()

        #expect(store.journalsPhase == .loaded)
        #expect(store.historyPhase == .loaded)
        #expect(store.journals.isEmpty)
        #expect(store.history.isEmpty)
        #expect(store.insightLoadingJournalIDs.isEmpty)
    }

    @Test("Loading fixture has loading list phases")
    func loadingFixture() {
        let store = MockData.loadingStore()

        #expect(store.journalsPhase == .loading)
        #expect(store.historyPhase == .loading)
        #expect(store.journals.isEmpty)
        #expect(store.history.isEmpty)
    }

    @Test("Unavailable-insight fixture keeps journals without insight state")
    func unavailableInsightFixture() {
        let store = MockData.unavailableInsightStore()

        #expect(store.journalsPhase == .loaded)
        #expect(!store.journals.isEmpty)
        #expect(store.history.isEmpty)
        #expect(store.insightLoadingJournalIDs.isEmpty)
    }

    @Test("Insight-loading fixture identifies its loading journal")
    func insightLoadingFixture() throws {
        let store = MockData.insightLoadingStore()
        let journal = try #require(store.journals.first)

        #expect(store.journalsPhase == .loaded)
        #expect(store.historyPhase == .loaded)
        #expect(store.insightLoadingJournalIDs == [journal.id])
    }
}
