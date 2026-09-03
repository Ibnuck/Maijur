import Foundation
import NaturalLanguage
import OSLog
import Translation

enum InsightDebugLog {
    static func fields(_ stage: String, _ fields: [(label: String, value: String)]) {
#if DEBUG
        let body = fields.map { field in
            "\(field.label):\n\(field.value)"
        }
        .joined(separator: "\n\n")

        print(
            """

            ┌─ MaiJur Insight Trace · \(stage)
            \(body)
            └─ End Trace

            """
        )
#endif
    }

    static func error(_ stage: String, _ error: Error) {
#if DEBUG
        fields(stage, [
            ("errorType", String(reflecting: type(of: error))),
            ("description", String(reflecting: error))
        ])
#endif
    }
}

@available(iOS 26.0, *)
struct JournalInsightLanguagePlan {
    let sourceLanguage: Locale.Language?
    let confidence: Double?
    let needsInputTranslation: Bool

    var inputTranslationConfiguration: TranslationSession.Configuration {
        TranslationSession.Configuration(
            source: nil,
            target: InsightLanguagePipeline.processingLanguage,
            preferredStrategy: .highFidelity
        )
    }
}

@available(iOS 26.0, *)
enum InsightLanguagePipeline {
    static let processingLanguage = Locale.Language(identifier: "en")
    static let displayLanguage = Locale.Language(identifier: "id")
    private static let minimumSourceConfidence = 0.70
    private static let minimumSourceMargin = 0.15
    private static let minimumPreferredLanguageConfidence = 0.55
    private static let minimumPreferredLanguageMargin = 0.30
    private static let languageHints: [NLLanguage: Double] = [
        .indonesian: 0.6,
        .english: 0.3
    ]
    private static let validationCache = NSCache<NSString, NSNumber>()
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MaiJur",
        category: "LanguageDetection"
    )

    static func journalPlan(for text: String) -> JournalInsightLanguagePlan {
        let detection = reliableSourceDetection(in: text)
        let sourceLanguage = detection?.language

        if let detection {
            logger.info(
                "NLP source candidate: \(detection.language.minimalIdentifier, privacy: .public), confidence: \(detection.confidence, format: .fixed(precision: 3), privacy: .public), candidates: \(detection.candidateSummary, privacy: .public)"
            )
            InsightDebugLog.fields("Language detection", [
                ("selectedLanguage", detection.language.minimalIdentifier),
                ("confidence", String(format: "%.3f", detection.confidence)),
                ("candidates", detection.candidateSummary)
            ])
        } else {
            logger.warning("Journal source language is uncertain; generation will stop before translation")
            InsightDebugLog.fields("Language detection", [
                ("result", "uncertain")
            ])
        }

        return JournalInsightLanguagePlan(
            sourceLanguage: sourceLanguage,
            confidence: detection?.confidence,
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

    static func verifyAutomaticTranslationSupport(for text: String) async throws {
        let availability = LanguageAvailability(preferredStrategy: .highFidelity)
        let status = try await availability.status(for: text, to: processingLanguage)
        logger.info(
            "Automatic translation availability: \(availabilityDescription(status), privacy: .public)"
        )

        guard status != .unsupported else {
            throw TranslationError.unsupportedSourceLanguage
        }
    }

    private static func reliableSourceDetection(in text: String) -> SourceLanguageDetection? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        let candidates = recognizer.languageHypotheses(withMaximum: 3)
            .map { (language: $0.key, confidence: $0.value) }
            .sorted { $0.confidence > $1.confidence }

        guard let first = candidates.first else { return nil }
        let secondConfidence = candidates.dropFirst().first?.confidence ?? 0
        let hasClearWinner = first.confidence >= minimumSourceConfidence
            && first.confidence - secondConfidence >= minimumSourceMargin
        let isPreferredLanguage = first.language == .indonesian || first.language == .english
        let hasReliablePreferredLanguage = isPreferredLanguage
            && first.confidence >= minimumPreferredLanguageConfidence
            && first.confidence - secondConfidence >= minimumPreferredLanguageMargin
        let isIndonesianEnglishMix = candidates.prefix(2).allSatisfy {
            $0.language == .indonesian || $0.language == .english
        } && candidates.prefix(2).reduce(0) { $0 + $1.confidence } >= minimumSourceConfidence

        guard hasClearWinner || hasReliablePreferredLanguage || isIndonesianEnglishMix else {
            let summary = candidateSummary(from: candidates)
            logger.warning(
                "Rejected uncertain journal language; candidates: \(summary, privacy: .public)"
            )
            return nil
        }

        let selectedLanguage: NLLanguage
        if isIndonesianEnglishMix {
            let hintedRecognizer = NLLanguageRecognizer()
            hintedRecognizer.languageHints = languageHints
            hintedRecognizer.processString(text)
            selectedLanguage = hintedRecognizer.dominantLanguage ?? first.language
        } else {
            selectedLanguage = first.language
        }
        let selectedConfidence = candidates.first {
            $0.language == selectedLanguage
        }?.confidence ?? first.confidence

        return SourceLanguageDetection(
            language: Locale.Language(identifier: selectedLanguage.rawValue),
            confidence: selectedConfidence,
            candidateSummary: candidateSummary(from: candidates)
        )
    }

    private static func candidateSummary(
        from candidates: [(language: NLLanguage, confidence: Double)]
    ) -> String {
        candidates.map {
            "\($0.language.rawValue):\(String(format: "%.3f", $0.confidence))"
        }
        .joined(separator: ",")
    }

    private static func availabilityDescription(
        _ status: LanguageAvailability.Status
    ) -> String {
        switch status {
        case .installed: "installed"
        case .supported: "supported"
        case .unsupported: "unsupported"
        @unknown default: "unknown"
        }
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

    static func hasPlausibleTranslationCoverage(
        sourceText: String,
        translatedText: String
    ) -> Bool {
        let sourceWordCount = wordCount(in: sourceText)
        let translatedWordCount = wordCount(in: translatedText)
        let minimumTranslatedWordCount = max(
            3,
            Int((Double(sourceWordCount) * 0.45).rounded(.up))
        )
        logger.info(
            "Translation coverage: source words \(sourceWordCount, privacy: .public), translated words \(translatedWordCount, privacy: .public), minimum \(minimumTranslatedWordCount, privacy: .public)"
        )
        return translatedWordCount >= minimumTranslatedWordCount
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

    private static func wordCount(in text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            if text[range].contains(where: { $0.isLetter || $0.isNumber }) {
                count += 1
            }
            return true
        }
        return count
    }
}

private struct SourceLanguageDetection {
    let language: Locale.Language
    let confidence: Double
    let candidateSummary: String
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

        InsightDebugLog.fields("Output translation · Journal insight", [
            ("summary · source en", analysis.summary),
            ("summary · target id", summary),
            ("reflection · source en", analysis.reflection),
            ("reflection · target id", reflection),
            ("themes · source en", analysis.digest),
            ("themes · target id", digest)
        ])

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

        InsightDebugLog.fields("Output translation · Overall insight", [
            ("overview · source en", insight.overview),
            ("overview · target id", overview),
            ("patterns · source en", insight.patterns),
            ("patterns · target id", patterns),
            ("recentFocus · source en", insight.recentFocus),
            ("recentFocus · target id", recentFocus)
        ])

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
