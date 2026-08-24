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
        #expect(first.insightLoadingJournalIDs.isEmpty)
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
