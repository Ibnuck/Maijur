import Foundation

struct OverallInsightSnapshot: Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let overview: String
    let patterns: String
    let recentFocus: String
    let processingOverview: String
    let processingPatterns: String
    let processingRecentFocus: String
    let displayLanguageCode: String
    let coveredInsightIDs: [UUID]
    let promptVersion: String

    init(
        id: UUID,
        createdAt: Date,
        updatedAt: Date,
        overview: String,
        patterns: String,
        recentFocus: String,
        processingOverview: String? = nil,
        processingPatterns: String? = nil,
        processingRecentFocus: String? = nil,
        displayLanguageCode: String = "id",
        coveredInsightIDs: [UUID],
        promptVersion: String = ""
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
    }

    func isCompatible(with currentPromptVersion: String) -> Bool {
        promptVersion.isEmpty || promptVersion == currentPromptVersion
    }
}
