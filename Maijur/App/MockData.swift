import Foundation

@MainActor
enum MockData {
    static var previewJournal: JournalEntry { journals[0] }

    static func populatedStore() -> JournalStore {
        JournalStore(journals: journals, history: history)
    }

    static func emptyStore() -> JournalStore {
        JournalStore()
    }

    static func overallInsightStore() -> JournalStore {
        JournalStore(
            journals: journals,
            history: history,
            overallInsight: OverallInsightSnapshot(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
                createdAt: Date(timeIntervalSince1970: 1_787_432_500),
                updatedAt: Date(timeIntervalSince1970: 1_787_432_500),
                overview: "Akhir-akhir ini, momen yang paling bermakna muncul ketika ada ruang untuk melambat dan terhubung dengan orang lain.",
                patterns: "Ketenangan dan hubungan yang sudah lama terjalin berulang kali memberi rasa pulih dan nyaman.",
                recentFocus: "Perhatian terbaru lebih banyak tertuju pada menikmati lingkungan sekitar dan memberi ruang bagi pikiran.",
                processingOverview: "Recently, the most meaningful moments appear when there is room to slow down and connect with other people.",
                processingPatterns: "• Restorative quiet\n• Longstanding connections",
                processingRecentFocus: "The newest entry focuses on noticing the surroundings and making room to think.",
                displayLanguageCode: "id",
                coveredInsightIDs: history.map(\.id),
                promptVersion: OverallInsightService.promptVersion
            )
        )
    }

    static func loadingStore() -> JournalStore {
        JournalStore(journalsPhase: .loading, historyPhase: .loading)
    }

    static func unavailableInsightStore() -> JournalStore {
        JournalStore(journals: journals)
    }

    static func insightLoadingStore() -> JournalStore {
        let journal = journals[0]
        return JournalStore(
            journals: [journal],
            insightLoadingJournalIDs: [journal.id]
        )
    }

    static func longListStore(count: Int = 500) -> JournalStore {
        let anchor = Date(timeIntervalSince1970: 1_787_428_800)
        let entries = (0..<count).map { index in
            JournalEntry(
                id: UUID(),
                date: anchor.addingTimeInterval(-TimeInterval(index * 86_400)),
                text: "Catatan performa nomor \(index + 1). Hari ini menyimpan satu hal kecil yang ingin diingat."
            )
        }
        return JournalStore(journals: entries)
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
            summary: "Perjalanan pulang yang reflektif memberi ruang untuk melambat dan memperhatikan suasana kota.",
            reflection: "Kamu tampaknya merasa lebih pulih ketika momen yang tidak direncanakan memberi ruang untuk memperhatikan sekitar.",
            digest: "• Ketenangan setelah hujan\n• Ruang untuk berpikir",
            processingSummary: "A reflective walk home created space to slow down and notice the city.",
            processingDigest: "• Quiet after rain\n• Space to think",
            sourceLanguageCode: "en",
            displayLanguageCode: "id",
            sourceContentHash: journals[0].contentHash,
            promptVersion: JournalAnalysisService.promptVersion
        ),
        HistorySnapshot(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
            sourceJournalID: journals[1].id,
            sourceJournalDate: journals[1].date,
            createdAt: Date(timeIntervalSince1970: 1_787_173_200),
            summary: "Berjumpa kembali dengan seorang teman terasa alami dan menenangkan.",
            reflection: "Hubungan yang sudah lama terjalin tampaknya terus memberimu rasa nyaman dan ringan.",
            digest: "• Persahabatan lama\n• Rasa nyaman",
            processingSummary: "Reconnecting with a friend felt natural and grounding.",
            processingDigest: "• Longstanding friendship\n• Ease and grounding",
            sourceLanguageCode: "en",
            displayLanguageCode: "id",
            sourceContentHash: journals[1].contentHash,
            promptVersion: JournalAnalysisService.promptVersion
        )
    ]
}
