import Foundation

struct HistorySnapshot: Equatable, Identifiable {
    let id: UUID
    let sourceJournalID: UUID
    let sourceJournalDate: Date
    let createdAt: Date
    let summary: String
    let reflection: String
    let digest: String
    let processingSummary: String
    let processingDigest: String
    let sourceLanguageCode: String
    let displayLanguageCode: String
    let sourceContentHash: String
    let promptVersion: String

    init(
        id: UUID,
        sourceJournalID: UUID,
        sourceJournalDate: Date,
        createdAt: Date,
        summary: String,
        reflection: String,
        digest: String,
        processingSummary: String? = nil,
        processingDigest: String? = nil,
        sourceLanguageCode: String = "en",
        displayLanguageCode: String = "en",
        sourceContentHash: String = "",
        promptVersion: String = ""
    ) {
        self.id = id
        self.sourceJournalID = sourceJournalID
        self.sourceJournalDate = sourceJournalDate
        self.createdAt = createdAt
        self.summary = summary
        self.reflection = reflection
        self.digest = digest
        self.processingSummary = processingSummary ?? summary
        self.processingDigest = processingDigest ?? digest
        self.sourceLanguageCode = sourceLanguageCode
        self.displayLanguageCode = displayLanguageCode
        self.sourceContentHash = sourceContentHash
        self.promptVersion = promptVersion
    }

    func belongsToCurrentRevision(of journal: JournalEntry) -> Bool {
        sourceJournalID == journal.id && (sourceContentHash.isEmpty || sourceContentHash == journal.contentHash)
    }

    func isCompatible(with currentPromptVersion: String) -> Bool {
        promptVersion == currentPromptVersion
    }

    func isDisplayed(in language: Locale.Language) -> Bool {
        Locale.Language(identifier: displayLanguageCode).isEquivalent(to: language)
    }

    func hasValidLanguageContract() -> Bool {
        isDisplayed(in: InsightLanguagePipeline.displayLanguage)
            && InsightLanguagePipeline.isValidJournalDisplay(
                summary: summary,
                reflection: reflection,
                digest: digest
            )
            && InsightLanguagePipeline.isValidJournalProcessing(
                summary: processingSummary,
                digest: processingDigest
            )
    }
}
