import SwiftUI

struct JournalDetailView: View {
    let journal: JournalEntry
    let store: JournalStore
    let onEdit: () -> Void

    @State private var isGeneratingInsights = false
    @State private var generationError: String?

    private var snapshot: HistorySnapshot? {
        store.history.first { $0.belongsToCurrentRevision(of: journal) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(journal.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(journal.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("journal-detail-text")
                }

                Divider()

                insightSection
            }
            .padding()
            .frame(maxWidth: 700, alignment: .leading)
        }
        .navigationTitle("Jurnal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    onEdit()
                }
                .accessibilityIdentifier("edit-journal-button")
            }
        }
        .alert("Insight Tidak Tersedia", isPresented: Binding(
            get: { generationError != nil },
            set: { if !$0 { generationError = nil } }
        )) {
            Button("Mengerti", role: .cancel) {
                generationError = nil
            }
        } message: {
            Text(generationError ?? "Silakan coba lagi.")
        }
    }

    @ViewBuilder
    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Insight", systemImage: "sparkles")
                .font(.title3.weight(.semibold))

            if isGeneratingInsights || store.insightLoadingJournalIDs.contains(journal.id) {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Menyiapkan insight…")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else if let snapshot {
                InsightCard(title: "Ringkasan", text: snapshot.summary)
                InsightCard(title: "Refleksi", text: snapshot.reflection)
                InsightCard(title: "Rangkuman", text: snapshot.digest)
            } else {
                VStack(spacing: 14) {
                    ContentUnavailableView(
                        "Belum Ada Insight",
                        systemImage: "sparkles",
                        description: Text("Buat ringkasan dan refleksi privat untuk jurnal ini.")
                    )

                    Button("Buat Insight", systemImage: "sparkles") {
                        Task { await generateInsights() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGeneratingInsights)
                    .accessibilityIdentifier("create-insights-button")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }

    private func generateInsights() async {
        isGeneratingInsights = true
        defer { isGeneratingInsights = false }

        do {
            let analysis = try await JournalAnalysisService().generate(
                for: journal,
                latestDigest: store.history.first?.digest
            )
            guard store.saveHistory(
                for: journal.id,
                summary: analysis.summary,
                reflection: analysis.reflection,
                digest: analysis.digest,
                coveredJournalIDs: [journal.id],
                promptVersion: JournalAnalysisService.promptVersion,
                modelVersion: "Apple on-device"
            ) != nil else {
                return
            }
        } catch {
            generationError = error.localizedDescription
        }
    }
}

private struct InsightCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Insight available") {
    NavigationStack {
        JournalDetailView(journal: MockData.previewJournal, store: MockData.populatedStore(), onEdit: {})
    }
}

#Preview("Insight unavailable") {
    NavigationStack {
        JournalDetailView(journal: MockData.previewJournal, store: MockData.unavailableInsightStore(), onEdit: {})
    }
}

#Preview("Insight loading", traits: .sizeThatFitsLayout) {
    NavigationStack {
        JournalDetailView(journal: MockData.previewJournal, store: MockData.insightLoadingStore(), onEdit: {})
    }
}
