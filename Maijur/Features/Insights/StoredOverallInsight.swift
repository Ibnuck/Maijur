import Foundation
import SwiftData

@Model
final class StoredOverallInsight {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var overview: String
    var patterns: String
    var recentFocus: String
    var coveredInsightIDs: [UUID]
    var promptVersion: String
    var modelVersion: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        overview: String,
        patterns: String,
        recentFocus: String,
        coveredInsightIDs: [UUID],
        promptVersion: String = "",
        modelVersion: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.overview = overview
        self.patterns = patterns
        self.recentFocus = recentFocus
        self.coveredInsightIDs = coveredInsightIDs
        self.promptVersion = promptVersion
        self.modelVersion = modelVersion
    }

    var snapshot: OverallInsightSnapshot {
        OverallInsightSnapshot(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            overview: overview,
            patterns: patterns,
            recentFocus: recentFocus,
            coveredInsightIDs: coveredInsightIDs,
            promptVersion: promptVersion
        )
    }
}
