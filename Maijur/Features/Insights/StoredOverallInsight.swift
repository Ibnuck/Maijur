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
    var processingOverview: String = ""
    var processingPatterns: String = ""
    var processingRecentFocus: String = ""
    var displayLanguageCode: String = "id"
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
        processingOverview: String? = nil,
        processingPatterns: String? = nil,
        processingRecentFocus: String? = nil,
        displayLanguageCode: String = "id",
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
        self.processingOverview = processingOverview ?? overview
        self.processingPatterns = processingPatterns ?? patterns
        self.processingRecentFocus = processingRecentFocus ?? recentFocus
        self.displayLanguageCode = displayLanguageCode
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
            processingOverview: processingOverview.isEmpty ? overview : processingOverview,
            processingPatterns: processingPatterns.isEmpty ? patterns : processingPatterns,
            processingRecentFocus: processingRecentFocus.isEmpty ? recentFocus : processingRecentFocus,
            displayLanguageCode: displayLanguageCode,
            coveredInsightIDs: coveredInsightIDs,
            promptVersion: promptVersion
        )
    }
}
