import Foundation
import FoundationModels
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
    static let overallDisplayLanguage = Locale.Language(identifier: "id")

    static func journalPlan(for text: String) -> JournalInsightLanguagePlan {
        let sourceLanguage = detectedLanguage(in: text)
        let canProcessDirectly = sourceLanguage.map { language in
            SystemLanguageModel.default.supportedLanguages.contains { supportedLanguage in
                supportedLanguage.isEquivalent(to: language)
            }
        } ?? false

        return JournalInsightLanguagePlan(
            sourceLanguage: sourceLanguage,
            needsInputTranslation: !canProcessDirectly
        )
    }

    static func detectedLanguage(in text: String) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
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
              let digest = translated["digest"]
        else { throw InsightTranslationError.incompleteTranslation }

        return JournalAnalysis(summary: summary, reflection: reflection, digest: digest)
    }

    static func overallInsight(
        from insight: OverallInsightGeneration,
        using session: TranslationSession
    ) async throws -> OverallInsightGeneration {
        let responses = try await session.translations(from: [
            .init(sourceText: insight.overview, clientIdentifier: "overview"),
            .init(sourceText: insight.reflection, clientIdentifier: "reflection"),
            .init(sourceText: insight.recentFocus, clientIdentifier: "recentFocus")
        ])
        let translated = Dictionary(uniqueKeysWithValues: responses.compactMap { response in
            response.clientIdentifier.map { ($0, response.targetText) }
        })

        guard let overview = translated["overview"],
              let reflection = translated["reflection"],
              let recentFocus = translated["recentFocus"]
        else { throw InsightTranslationError.incompleteTranslation }

        return OverallInsightGeneration(
            overview: overview,
            reflection: reflection,
            recentFocus: recentFocus,
            coveredInsightIDs: insight.coveredInsightIDs
        )
    }
}

enum InsightTranslationError: LocalizedError {
    case incompleteTranslation

    var errorDescription: String? {
        switch self {
        case .incompleteTranslation:
            "Terjemahan belum lengkap. Jurnalmu tetap aman; silakan coba lagi."
        }
    }
}
