import Foundation

struct OverallInsightSnapshot: Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let overview: String
    let patterns: String
    let recentFocus: String
    let coveredInsightIDs: [UUID]

    var compactContext: String {
        """
        Gambaran besar: \(overview)
        Pola: \(patterns)
        Fokus terbaru: \(recentFocus)
        """
    }
}
