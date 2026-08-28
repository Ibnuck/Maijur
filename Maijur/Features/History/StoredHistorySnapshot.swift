import Foundation
import SwiftData

@Model
final class StoredHistorySnapshot {
    @Attribute(.unique) var id: UUID
    var sourceJournalID: UUID
    var sourceJournalDate: Date
    var sourceRevision: Int
    var sourceContentHash: String
    var createdAt: Date
    var summary: String
    var reflection: String
    var digest: String
    var processingSummary: String = ""
    var processingDigest: String = ""
    var sourceLanguageCode: String = "en"
    var displayLanguageCode: String = "en"
    var coveredJournalIDs: [UUID]
    var promptVersion: String
    var modelVersion: String

    init(
        id: UUID = UUID(),
        sourceJournalID: UUID,
        sourceJournalDate: Date,
        sourceRevision: Int,
        sourceContentHash: String,
        createdAt: Date = .now,
        summary: String,
        reflection: String,
        digest: String,
        processingSummary: String? = nil,
        processingDigest: String? = nil,
        sourceLanguageCode: String = "en",
        displayLanguageCode: String = "en",
        coveredJournalIDs: [UUID] = [],
        promptVersion: String = "",
        modelVersion: String = ""
    ) {
        self.id = id
        self.sourceJournalID = sourceJournalID
        self.sourceJournalDate = sourceJournalDate
        self.sourceRevision = sourceRevision
        self.sourceContentHash = sourceContentHash
        self.createdAt = createdAt
        self.summary = summary
        self.reflection = reflection
        self.digest = digest
        self.processingSummary = processingSummary ?? summary
        self.processingDigest = processingDigest ?? digest
        self.sourceLanguageCode = sourceLanguageCode
        self.displayLanguageCode = displayLanguageCode
        self.coveredJournalIDs = coveredJournalIDs
        self.promptVersion = promptVersion
        self.modelVersion = modelVersion
    }

    var snapshot: HistorySnapshot {
        HistorySnapshot(
            id: id,
            sourceJournalID: sourceJournalID,
            sourceJournalDate: sourceJournalDate,
            createdAt: createdAt,
            summary: summary,
            reflection: reflection,
            digest: digest,
            processingSummary: processingSummary.isEmpty ? summary : processingSummary,
            processingDigest: processingDigest.isEmpty ? digest : processingDigest,
            sourceLanguageCode: sourceLanguageCode,
            displayLanguageCode: displayLanguageCode,
            sourceContentHash: sourceContentHash,
            promptVersion: promptVersion
        )
    }
}
