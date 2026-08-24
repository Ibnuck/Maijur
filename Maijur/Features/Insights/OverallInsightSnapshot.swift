import Foundation

struct OverallInsightSnapshot: Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let overview: String
    let patterns: String
    let recentFocus: String
    let coveredInsightIDs: [UUID]
    let promptVersion: String

    init(
        id: UUID,
        createdAt: Date,
        updatedAt: Date,
        overview: String,
        patterns: String,
        recentFocus: String,
        coveredInsightIDs: [UUID],
        promptVersion: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.overview = overview
        self.patterns = patterns
        self.recentFocus = recentFocus
        self.coveredInsightIDs = coveredInsightIDs
        self.promptVersion = promptVersion
    }

    func isCompatible(with currentPromptVersion: String) -> Bool {
        promptVersion.isEmpty || promptVersion == currentPromptVersion
    }
}
