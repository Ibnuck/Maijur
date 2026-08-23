import Foundation

@MainActor
enum MockData {
    static func populatedStore() -> MockJournalStore {
        MockJournalStore(journals: journals, history: history)
    }

    static func emptyStore() -> MockJournalStore {
        MockJournalStore()
    }

    static func loadingStore() -> MockJournalStore {
        MockJournalStore(journalsPhase: .loading, historyPhase: .loading)
    }

    static func unavailableInsightStore() -> MockJournalStore {
        MockJournalStore(journals: journals)
    }

    static func insightLoadingStore() -> MockJournalStore {
        let journal = journals[0]
        return MockJournalStore(
            journals: [journal],
            insightLoadingJournalIDs: [journal.id]
        )
    }

    private static let journals = [
        JournalEntry(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            date: Date(timeIntervalSince1970: 1_787_428_800),
            text: "I took the long way home and noticed how quiet the city felt after the rain. It gave me room to think."
        ),
        JournalEntry(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            date: Date(timeIntervalSince1970: 1_787_169_600),
            text: "Lunch with an old friend reminded me that some conversations pick up exactly where they left off."
        ),
        JournalEntry(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            date: Date(timeIntervalSince1970: 1_786_737_600),
            text: "A slow morning, a warm cup of tea, and enough time to finish the book on my nightstand."
        )
    ]

    private static let history = [
        HistorySnapshot(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            sourceJournalID: journals[0].id,
            sourceJournalDate: journals[0].date,
            createdAt: Date(timeIntervalSince1970: 1_787_432_400),
            summary: "A reflective walk home created space to slow down and notice the city.",
            reflection: "You seem restored by unplanned moments that leave room for attention.",
            digest: "Recent entries return to friendship, quiet routines, and making space to notice everyday life."
        ),
        HistorySnapshot(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
            sourceJournalID: journals[1].id,
            sourceJournalDate: journals[1].date,
            createdAt: Date(timeIntervalSince1970: 1_787_173_200),
            summary: "Reconnecting with a friend felt natural and grounding.",
            reflection: "Longstanding relationships continue to offer you a sense of ease.",
            digest: "Connection and calm have shaped the most meaningful moments this week."
        )
    ]
}
