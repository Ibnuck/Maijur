import Foundation
import NaturalLanguage
import Translation

@available(iOS 26.0, *)
struct JournalInsightLanguagePlan {
    let sourceLanguage: Locale.Language?
    let needsInputTranslation: Bool

    var inputTranslationConfiguration: TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: sourceLanguage,
            target: InsightLanguagePipeline.processingLanguage,
            preferredStrategy: .highFidelity
        )
    }
}

@available(iOS 26.0, *)
enum InsightLanguagePipeline {
    static let processingLanguage = Locale.Language(identifier: "en")
    static let displayLanguage = Locale.Language(identifier: "id")
    private static let languageHints: [NLLanguage: Double] = [
        .indonesian: 0.6,
        .english: 0.3
    ]
    private static let validationCache = NSCache<NSString, NSNumber>()

    static func journalPlan(for text: String) -> JournalInsightLanguagePlan {
        let sourceLanguage = detectedLanguage(in: text)

        return JournalInsightLanguagePlan(
            sourceLanguage: sourceLanguage,
            needsInputTranslation: sourceLanguage.map { !isEnglish($0) } ?? false
        )
    }

    static func detectedLanguage(in text: String) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageHints = languageHints
        recognizer.processString(text)

        guard let language = recognizer.dominantLanguage else { return nil }
        return Locale.Language(identifier: language.rawValue)
    }

    static func isEnglish(_ language: Locale.Language) -> Bool {
        language.isEquivalent(to: processingLanguage)
    }

    static func languageCode(for language: Locale.Language) -> String {
        language.minimalIdentifier
    }

    static func isValidJournalDisplay(
        summary: String,
        reflection: String,
        digest: String
    ) -> Bool {
        isValid(
            [summary, reflection, digest],
            proseFieldIndices: [0, 1],
            in: displayLanguage
        )
    }

    static func isValidOverallDisplay(
        overview: String,
        patterns: String,
        recentFocus: String
    ) -> Bool {
        isValid(
            [overview, patterns, recentFocus],
            proseFieldIndices: [0, 2],
            in: displayLanguage
        )
    }

    static func isValidTranslatedInput(_ text: String) -> Bool {
        isValid([text], proseFieldIndices: [0], in: processingLanguage)
    }

    static func isValidJournalProcessing(
        summary: String,
        reflection: String? = nil,
        digest: String
    ) -> Bool {
        let fields = reflection.map { [summary, $0, digest] } ?? [summary, digest]
        let proseFieldIndices: Set<Int> = reflection == nil ? [0] : [0, 1]
        return isValid(fields, proseFieldIndices: proseFieldIndices, in: processingLanguage)
    }

    static func isValidOverallProcessing(
        overview: String,
        patterns: String,
        recentFocus: String
    ) -> Bool {
        isValid(
            [overview, patterns, recentFocus],
            proseFieldIndices: [0, 2],
            in: processingLanguage
        )
    }

    private static func isValid(
        _ fields: [String],
        proseFieldIndices: Set<Int>,
        in expectedLanguage: Locale.Language
    ) -> Bool {
        let trimmedFields = fields.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !trimmedFields.isEmpty,
              trimmedFields.allSatisfy({ !$0.isEmpty }),
              text(trimmedFields.joined(separator: "\n"), isIn: expectedLanguage)
        else { return false }

        return proseFieldIndices.allSatisfy { index in
            trimmedFields.indices.contains(index)
                && text(trimmedFields[index], isIn: expectedLanguage)
        }
    }

    private static func text(_ text: String, isIn expectedLanguage: Locale.Language) -> Bool {
        let cacheKey = "\(expectedLanguage.minimalIdentifier)\u{0}\(text)" as NSString
        if let cachedResult = validationCache.object(forKey: cacheKey) {
            return cachedResult.boolValue
        }

        let isValid = detectedLanguage(in: text)?.isEquivalent(to: expectedLanguage) == true
        validationCache.setObject(NSNumber(value: isValid), forKey: cacheKey)
        return isValid
    }
}

@available(iOS 26.0, *)
enum InsightTranslation {
    static func journalAnalysis(
        from analysis: JournalAnalysis,
        using session: TranslationSession
    ) async throws -> JournalAnalysis {
        let responses = try await session.translations(from: [
            .init(sourceText: analysis.summary, clientIdentifier: "summary"),
            .init(sourceText: analysis.reflection, clientIdentifier: "reflection"),
            .init(sourceText: analysis.digest, clientIdentifier: "digest")
        ])
        let translated = Dictionary(uniqueKeysWithValues: responses.compactMap { response in
            response.clientIdentifier.map { ($0, response.targetText) }
        })

        guard let summary = translated["summary"],
              let reflection = translated["reflection"],
              let digest = translated["digest"],
              InsightLanguagePipeline.isValidJournalDisplay(
                summary: summary,
                reflection: reflection,
                digest: digest
              )
        else { throw InsightTranslationError.incompleteTranslation }

        return JournalAnalysis(summary: summary, reflection: reflection, digest: digest)
    }

    static func overallInsight(
        from insight: OverallInsightGeneration,
        using session: TranslationSession
    ) async throws -> OverallInsightGeneration {
        let responses = try await session.translations(from: [
            .init(sourceText: insight.overview, clientIdentifier: "overview"),
            .init(sourceText: insight.patterns, clientIdentifier: "patterns"),
            .init(sourceText: insight.recentFocus, clientIdentifier: "recentFocus")
        ])
        let translated = Dictionary(uniqueKeysWithValues: responses.compactMap { response in
            response.clientIdentifier.map { ($0, response.targetText) }
        })

        guard let overview = translated["overview"],
              let patterns = translated["patterns"],
              let recentFocus = translated["recentFocus"],
              InsightLanguagePipeline.isValidOverallDisplay(
                overview: overview,
                patterns: patterns,
                recentFocus: recentFocus
              )
        else { throw InsightTranslationError.incompleteTranslation }

        return OverallInsightGeneration(
            overview: overview,
            patterns: patterns,
            recentFocus: recentFocus,
            coveredInsightIDs: insight.coveredInsightIDs
        )
    }
}

enum InsightTranslationError: LocalizedError {
    case incompleteTranslation
    case invalidProcessingLanguage

    var errorDescription: String? {
        switch self {
        case .incompleteTranslation:
            "Terjemahan belum lengkap. Jurnalmu tetap aman; silakan coba lagi."
        case .invalidProcessingLanguage:
            "Bahasa pemrosesan insight belum sesuai. Jurnalmu tetap aman; silakan coba lagi."
        }
    }
}
