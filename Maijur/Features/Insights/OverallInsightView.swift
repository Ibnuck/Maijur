import SwiftUI
import Translation

struct OverallInsightView: View {
    let store: JournalStore

    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var outputTranslationConfiguration: TranslationSession.Configuration?
    @State private var pendingInsights: [HistorySnapshot] = []

    private var insight: OverallInsightSnapshot? { store.overallInsight }
    private var pendingCount: Int { store.pendingOverallInsights.count }

    var body: some View {
        ZStack {
            InsightPageBackground()

            ScrollView {
                VStack(spacing: 20) {
                    OverallInsightHeader(
                        updatedAt: insight?.updatedAt,
                        pendingCount: pendingCount
                    )

                    if isGenerating {
                        OverallInsightLoadingView()
                    } else if let insight {
                        OverallInsightCards(insight: insight)

                        OverallInsightAction(
                            pendingCount: pendingCount,
                            action: { Task { await generateOverallInsight() } }
                        )
                    } else if store.currentJournalInsights.isEmpty {
                        ContentUnavailableView {
                            Label("Belum Ada Bahan Insight", systemImage: "sparkles.rectangle.stack")
                        } description: {
                            Text("Buat insight dari detail jurnal terlebih dahulu. Jurnal tanpa insight akan dilewati.")
                        }
                        .padding(.vertical, 30)
                    } else {
                        OverallInsightIntroduction(count: pendingCount)
                        OverallInsightAction(
                            pendingCount: pendingCount,
                            action: { Task { await generateOverallInsight() } }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(generationError != nil)
        .navigationTitle("Insight Keseluruhan")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if let generationError {
                MaiJurAlert(
                    symbol: "sparkles.rectangle.stack",
                    tint: .indigo,
                    title: insight == nil
                        ? "Insight belum dapat dibuat"
                        : "Insight belum dapat diperbarui",
                    message: generationError,
                    primaryTitle: "Tutup",
                    primaryRole: nil,
                    primaryAction: {
                        self.generationError = nil
                    }
                )
            }
        }
        .translationTask(outputTranslationConfiguration) { session in
            await generateAndTranslate(using: session)
        }
    }

    private func generateOverallInsight() async {
        let newInsights = store.pendingOverallInsights
        guard !newInsights.isEmpty else { return }

        isGenerating = true
        pendingInsights = newInsights
        outputTranslationConfiguration = TranslationSession.Configuration(
            source: InsightLanguagePipeline.processingLanguage,
            target: InsightLanguagePipeline.overallDisplayLanguage,
            preferredStrategy: .highFidelity
        )
    }

    private func generateAndTranslate(using session: TranslationSession) async {
        guard !pendingInsights.isEmpty else { return }
        let newInsights = pendingInsights
        pendingInsights = []

        do {
            let processingInsight = try await OverallInsightService().generate(
                previous: store.overallInsight,
                newInsights: newInsights
            )
            let displayInsight = try await InsightTranslation.overallInsight(
                from: processingInsight,
                using: session
            )
            store.saveOverallInsight(
                overview: displayInsight.overview,
                patterns: displayInsight.patterns,
                recentFocus: displayInsight.recentFocus,
                processingOverview: processingInsight.overview,
                processingPatterns: processingInsight.patterns,
                processingRecentFocus: processingInsight.recentFocus,
                displayLanguageCode: InsightLanguagePipeline.languageCode(
                    for: InsightLanguagePipeline.overallDisplayLanguage
                ),
                coveredInsightIDs: processingInsight.coveredInsightIDs,
                promptVersion: OverallInsightService.promptVersion,
                modelVersion: "Apple on-device + Translation"
            )
        } catch {
            generationError = InsightAlertCopy.message(for: error)
        }

        outputTranslationConfiguration = nil
        isGenerating = false
    }
}

private struct OverallInsightHeader: View {
    let updatedAt: Date?
    let pendingCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Cerita besarmu")
                    .font(.title3.weight(.bold))

                if let updatedAt {
                    Text("Diperbarui \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Dirangkai dari insight jurnal yang sudah tersedia.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            if pendingCount > 0 {
                Text("\(pendingCount) baru")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.indigo.opacity(0.12), in: Capsule())
            } else if updatedAt != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Sudah mencakup semua insight jurnal terbaru")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct OverallInsightAction: View {
    let pendingCount: Int
    let action: () -> Void

    var body: some View {
        Group {
            if pendingCount > 0 {
                Button(action: action) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pendingCount == 1 ? "Ada 1 insight baru" : "Ada \(pendingCount) insight baru")
                                .font(.subheadline.weight(.semibold))
                            Text("Perbarui cerita besarmu")
                                .font(.caption)
                                .opacity(0.84)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("create-overall-insight-button")
            }
        }
    }
}

private struct OverallInsightIntroduction: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("\(count) insight jurnal siap diolah", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.indigo)

            Text("MaiJur memproses maksimal tiga insight per sesi. Hasil setiap sesi diteruskan ke sesi berikutnya, dengan perhatian lebih besar pada jurnal terbaru.")
                .font(.body)

            Label("Jurnal yang belum memiliki insight akan dilewati.", systemImage: "forward.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

private struct OverallInsightLoadingView: View {
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            VStack(spacing: 5) {
                Text("Menghubungkan perjalananmu…")
                    .font(.headline)
                Text("Insight baru sedang dipadukan dengan gambaran yang sudah tersimpan.")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Menghubungkan perjalananmu")
        .accessibilityValue("Insight baru sedang dipadukan dengan gambaran yang sudah tersimpan.")
    }
}

private struct OverallInsightCards: View {
    let insight: OverallInsightSnapshot

    var body: some View {
        VStack(spacing: 14) {
            InsightContentCard(
                icon: "rectangle.3.group.bubble.fill",
                title: "Gambaran Besar",
                text: insight.overview
            )
            InsightContentCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Pola yang Berkembang",
                text: insight.patterns
            )
            InsightContentCard(
                icon: "scope",
                title: "Yang Sedang Menonjol",
                text: insight.recentFocus
            )
        }
    }
}

#Preview("Belum dibuat") {
    NavigationStack {
        OverallInsightView(store: MockData.populatedStore())
    }
}

#Preview("Tersedia") {
    NavigationStack {
        OverallInsightView(store: MockData.overallInsightStore())
    }
}
