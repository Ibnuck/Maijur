import SwiftData
import XCTest
@testable import Maijur

final class JournalPerformanceTests: XCTestCase {
    @MainActor
    func testLocalPersistenceRoundTripPerformance() throws {
        let container = try ModelContainer(
            for: StoredJournal.self,
            StoredHistorySnapshot.self,
            StoredOverallInsight.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = JournalStore(modelContext: container.mainContext)

        measure {
            let entry = store.createJournal(date: .now, text: "Catatan pengukuran lokal")
            if let entry {
                _ = store.updateJournal(id: entry.id, date: entry.date, text: "Catatan pengukuran lokal diperbarui")
                _ = store.deleteJournal(id: entry.id)
            }
        }
    }
}
