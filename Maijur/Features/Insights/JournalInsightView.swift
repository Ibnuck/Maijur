import SwiftUI
import Translation

struct JournalInsightView: View {
    let journal: JournalEntry
    let store: JournalStore

    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var inputTranslationConfiguration: TranslationSession.Configuration?
    @State private var outputTranslationConfiguration: TranslationSession.Configuration?
    @State private var inputTranslationJournal: JournalEntry?
    @State private var outputTranslationJob: JournalOutputTranslationJob?

    private var snapshot: HistorySnapshot? {
        store.history.first {
            $0.belongsToCurrentRevision(of: journal)
                && $0.isCompatible(with: JournalAnalysisService.promptVersion)
                && $0.hasValidLanguageContract()
        }
    }

    var body: some View {
        ZStack {
            InsightPageBackground()

            ScrollView {
                VStack(spacing: 16) {
                    InsightHero(date: journal.date, hasResult: snapshot != nil)

                    if isGenerating || store.insightLoadingJournalIDs.contains(journal.id) {
                        InsightLoadingView()
                    } else if let snapshot {
                        InsightResultCards(snapshot: snapshot)
                    } else {
                        InsightIntroduction()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(generationError != nil)
        .navigationTitle("Insight")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if snapshot == nil && !isGenerating {
                Button {
                    Task { await generateInsights() }
                } label: {
                    Label("Buat Insight Personal", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
                .accessibilityIdentifier("create-insights-button")
            }
        }
        .overlay {
            if let generationError {
                MaiJurAlert(
                    symbol: "sparkles",
                    tint: .indigo,
                    title: "Insight belum dapat dibuat",
                    message: generationError,
                    primaryTitle: "Tutup",
                    primaryRole: nil,
                    primaryAction: {
                        self.generationError = nil
                    }
                )
            }
        }
        .translationTask(inputTranslationConfiguration) { session in
            await continueAfterInputTranslation(using: session)
        }
        .translationTask(outputTranslationConfiguration) { session in
            await finishOutputTranslation(using: session)
        }
    }

    private func generateInsights() async {
        isGenerating = true

        do {
            try InsightInputValidator.validate(journal.text)
        } catch {
            finish(with: error)
            return
        }

        let plan = InsightLanguagePipeline.journalPlan(for: journal.text)

        if plan.needsInputTranslation {
            inputTranslationJournal = journal
            inputTranslationConfiguration = plan.inputTranslationConfiguration
            return
        }

        guard let sourceLanguage = plan.sourceLanguage else {
            finish(with: JournalAnalysisError.languageDetectionFailed)
            return
        }

        do {
            let analysis = try await JournalAnalysisService().generate(for: journal)
            requestOutputTranslation(analysis, sourceLanguage: sourceLanguage)
        } catch {
            finish(with: error)
        }
    }

    private func continueAfterInputTranslation(using session: TranslationSession) async {
        guard let inputTranslationJournal else { return }
        self.inputTranslationJournal = nil

        do {
            let translation = try await session.translate(inputTranslationJournal.text)
            guard InsightLanguagePipeline.isValidTranslatedInput(translation.targetText) else {
                throw InsightTranslationError.invalidProcessingLanguage
            }
            let analysis = try await JournalAnalysisService().generate(
                for: inputTranslationJournal,
                processingText: translation.targetText
            )
            requestOutputTranslation(analysis, sourceLanguage: translation.sourceLanguage)
        } catch {
            finish(with: error)
        }
    }

    private func requestOutputTranslation(
        _ analysis: JournalAnalysis,
        sourceLanguage: Locale.Language
    ) {
        guard InsightLanguagePipeline.isValidJournalProcessing(
            summary: analysis.summary,
            reflection: analysis.reflection,
            digest: analysis.digest
        ) else {
            finish(with: InsightTranslationError.invalidProcessingLanguage)
            return
        }

        outputTranslationJob = JournalOutputTranslationJob(
            analysis: analysis,
            sourceLanguage: sourceLanguage
        )
        outputTranslationConfiguration = TranslationSession.Configuration(
            source: InsightLanguagePipeline.processingLanguage,
            target: InsightLanguagePipeline.displayLanguage,
            preferredStrategy: .highFidelity
        )
    }

    private func finishOutputTranslation(using session: TranslationSession) async {
        guard let outputTranslationJob else { return }
        self.outputTranslationJob = nil

        do {
            let displayAnalysis = try await InsightTranslation.journalAnalysis(
                from: outputTranslationJob.analysis,
                using: session
            )
            save(
                displayAnalysis,
                processingAnalysis: outputTranslationJob.analysis,
                sourceLanguage: outputTranslationJob.sourceLanguage
            )
        } catch {
            finish(with: error)
        }
    }

    private func save(
        _ displayAnalysis: JournalAnalysis,
        processingAnalysis: JournalAnalysis? = nil,
        sourceLanguage: Locale.Language
    ) {
        let processingAnalysis = processingAnalysis ?? displayAnalysis
        guard store.saveHistory(
            for: journal.id,
            summary: displayAnalysis.summary,
            reflection: displayAnalysis.reflection,
            digest: displayAnalysis.digest,
            processingSummary: processingAnalysis.summary,
            processingDigest: processingAnalysis.digest,
            sourceLanguageCode: InsightLanguagePipeline.languageCode(for: sourceLanguage),
            displayLanguageCode: InsightLanguagePipeline.languageCode(
                for: InsightLanguagePipeline.displayLanguage
            ),
            coveredJournalIDs: [journal.id],
            promptVersion: JournalAnalysisService.promptVersion,
            modelVersion: "Apple on-device + Translation"
        ) != nil else {
            finish(with: JournalAnalysisError.persistenceFailed)
            return
        }
        finish()
    }

    private func finish(with error: Error? = nil) {
        inputTranslationConfiguration = nil
        outputTranslationConfiguration = nil
        inputTranslationJournal = nil
        outputTranslationJob = nil
        isGenerating = false

        if let error {
            generationError = InsightAlertCopy.message(for: error)
        }
    }
}

private struct JournalOutputTranslationJob {
    let analysis: JournalAnalysis
    let sourceLanguage: Locale.Language
}

private struct InsightHero: View {
    let date: Date
    let hasResult: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasResult ? "sparkles.rectangle.stack.fill" : "sparkles")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.indigo.opacity(0.18), radius: 16, y: 7)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(hasResult ? "Ruang refleksimu" : "Kenali ceritamu lebih dalam")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(date.formatted(
                    .dateTime
                        .weekday(.wide)
                        .month(.wide)
                        .day()
                        .year()
                        .locale(Locale(identifier: "id_ID"))
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 5)
    }
}

private struct InsightIntroduction: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Yang akan kamu dapatkan")
                .font(.headline)

            InsightFeatureRow(
                icon: "text.alignleft",
                title: "Inti Cerita",
                description: "Inti pengalamanmu dalam bentuk yang lebih mudah dipahami."
            )
            InsightFeatureRow(
                icon: "quote.bubble",
                title: "Ruang Refleksi",
                description: "Sudut pandang hangat untuk membantu mengenali pikiran dan perasaanmu."
            )
            InsightFeatureRow(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Tema Utama",
                description: "Tema penting yang paling menonjol dalam jurnal ini."
            )

            Label("Diproses langsung di iPhone dan disimpan secara lokal.", systemImage: "lock.shield")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct InsightFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.indigo)
                .frame(width: 36, height: 36)
                .background(Color.indigo.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct InsightLoadingView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            VStack(spacing: 5) {
                Text("Menyiapkan insight personal…")
                    .font(.headline)
                Text("MaiJur sedang memahami cerita, menyusun refleksi, dan mengenali pola yang berkembang.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .padding(.horizontal, 24)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityIdentifier("insight-loading-view")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Menyiapkan insight personal")
        .accessibilityValue("MaiJur sedang memahami cerita, menyusun refleksi, dan mengenali tema.")
    }
}

struct InsightResultCards: View {
    let snapshot: HistorySnapshot

    var body: some View {
        VStack(spacing: 14) {
            Label("Tersimpan bersama jurnal", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)

            InsightContentCard(
                icon: "text.alignleft",
                title: "Inti Cerita",
                text: snapshot.summary
            )
            InsightContentCard(
                icon: "quote.bubble.fill",
                title: "Ruang Refleksi",
                text: snapshot.reflection
            )
            InsightContentCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Tema Utama",
                text: snapshot.digest
            )
        }
    }
}

struct InsightContentCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(width: 34, height: 34)
                    .background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.headline)
            }

            Text(text)
                .font(.body)
                .lineSpacing(5)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 5)
    }
}

struct InsightPageBackground: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
            Circle()
                .fill(Color.indigo.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: 100, y: -140)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("Insight belum dibuat") {
    NavigationStack {
        JournalInsightView(journal: MockData.previewJournal, store: MockData.unavailableInsightStore())
    }
}

#Preview("Insight tersedia") {
    NavigationStack {
        JournalInsightView(journal: MockData.previewJournal, store: MockData.populatedStore())
    }
}

#Preview("Insight sedang dibuat") {
    NavigationStack {
        JournalInsightView(journal: MockData.previewJournal, store: MockData.insightLoadingStore())
    }
}
