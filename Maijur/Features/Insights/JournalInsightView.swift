import SwiftUI

struct JournalInsightView: View {
    let journal: JournalEntry
    let store: JournalStore

    @State private var isGenerating = false
    @State private var generationError: String?

    private var snapshot: HistorySnapshot? {
        store.history.first {
            $0.belongsToCurrentRevision(of: journal) && $0.isCompatible(with: JournalAnalysisService.promptVersion)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                InsightHero(date: journal.date, hasResult: snapshot != nil)

                if isGenerating || store.insightLoadingJournalIDs.contains(journal.id) {
                    InsightLoadingView()
                } else if let snapshot {
                    InsightResultCards(snapshot: snapshot)
                } else {
                    InsightIntroduction()
                }
            }
            .padding()
            .frame(maxWidth: 700)
        }
        .background(Color(.systemGroupedBackground))
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
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
                .accessibilityIdentifier("create-insights-button")
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

    private func generateInsights() async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let analysis = try await JournalAnalysisService().generate(for: journal)
            store.saveHistory(
                for: journal.id,
                summary: analysis.summary,
                reflection: analysis.reflection,
                digest: analysis.digest,
                coveredJournalIDs: [journal.id],
                promptVersion: JournalAnalysisService.promptVersion,
                modelVersion: "Apple on-device"
            )
        } catch {
            generationError = error.localizedDescription
        }
    }
}

private struct InsightHero: View {
    let date: Date
    let hasResult: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasResult ? "sparkles.rectangle.stack.fill" : "sparkles")
                .font(.system(size: 38, weight: .medium))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .yellow)
                .frame(width: 76, height: 76)
                .background(Color.accentColor.gradient, in: Circle())

            VStack(spacing: 6) {
                Text(hasResult ? "Ruang refleksimu" : "Kenali ceritamu lebih dalam")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.accentColor.opacity(0.16), lineWidth: 1)
        }
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
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: Circle())

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
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityIdentifier("insight-loading-view")
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

            InsightResultCard(
                icon: "text.alignleft",
                title: "Inti Cerita",
                text: snapshot.summary,
                color: .blue
            )
            InsightResultCard(
                icon: "quote.bubble.fill",
                title: "Ruang Refleksi",
                text: snapshot.reflection,
                color: .purple
            )
            InsightResultCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Tema Utama",
                text: snapshot.digest,
                color: .orange
            )
        }
    }
}

private struct InsightResultCard: View {
    let icon: String
    let title: String
    let text: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .leading) {
            Capsule()
                .fill(color.gradient)
                .frame(width: 4)
                .padding(.vertical, 18)
        }
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
