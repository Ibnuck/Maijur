import SwiftUI

struct OverallInsightView: View {
    let store: JournalStore

    @State private var isGenerating = false
    @State private var generationError: String?

    private var insight: OverallInsightSnapshot? { store.overallInsight }
    private var pendingCount: Int { store.pendingOverallInsights.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                OverallInsightHero(hasResult: insight != nil)

                if isGenerating {
                    OverallInsightLoadingView()
                } else if let insight {
                    OverallInsightCards(insight: insight)

                    if pendingCount == 0 {
                        Label("Sudah mencakup semua insight jurnal terbaru", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                } else if store.currentJournalInsights.isEmpty {
                    ContentUnavailableView {
                        Label("Belum Ada Bahan Insight", systemImage: "sparkles.rectangle.stack")
                    } description: {
                        Text("Buat insight dari detail jurnal terlebih dahulu. Jurnal tanpa insight akan dilewati.")
                    }
                    .padding(.vertical, 30)
                } else {
                    OverallInsightIntroduction(count: pendingCount)
                }
            }
            .padding()
            .frame(maxWidth: 700)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Insight Keseluruhan")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if pendingCount > 0 && !isGenerating {
                Button {
                    Task { await generateOverallInsight() }
                } label: {
                    Label(buttonTitle, systemImage: "sparkles.rectangle.stack")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
                .accessibilityIdentifier("create-overall-insight-button")
            }
        }
        .alert("Insight Tidak Tersedia", isPresented: Binding(
            get: { generationError != nil },
            set: { if !$0 { generationError = nil } }
        )) {
            Button("Mengerti", role: .cancel) { generationError = nil }
        } message: {
            Text(generationError ?? "Silakan coba lagi.")
        }
    }

    private var buttonTitle: String {
        if insight == nil { return "Buat Insight Keseluruhan" }
        return "Perbarui dengan \(pendingCount) Insight Baru"
    }

    private func generateOverallInsight() async {
        let newInsights = store.pendingOverallInsights
        guard !newInsights.isEmpty else { return }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let result = try await OverallInsightService().generate(
                previous: store.overallInsight,
                newInsights: newInsights
            )
            store.saveOverallInsight(
                overview: result.overview,
                patterns: result.patterns,
                recentFocus: result.recentFocus,
                coveredInsightIDs: result.coveredInsightIDs,
                promptVersion: OverallInsightService.promptVersion,
                modelVersion: "Apple on-device"
            )
        } catch {
            generationError = error.localizedDescription
        }
    }
}

private struct OverallInsightHero: View {
    let hasResult: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .font(.system(size: 38, weight: .medium))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .mint)
                .frame(width: 76, height: 76)
                .background(Color.indigo.gradient, in: Circle())

            VStack(spacing: 6) {
                Text(hasResult ? "Cerita besarmu" : "Lihat perjalananmu lebih utuh")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("Disusun dari insight jurnal yang sudah tersedia, bukan dari teks jurnal mentah.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.indigo.opacity(0.16), lineWidth: 1)
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
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct OverallInsightCards: View {
    let insight: OverallInsightSnapshot

    var body: some View {
        VStack(spacing: 14) {
            OverallInsightCard(
                icon: "rectangle.3.group.bubble.fill",
                title: "Gambaran Besar",
                text: insight.overview,
                color: .indigo
            )
            OverallInsightCard(
                icon: "point.3.connected.trianglepath.dotted",
                title: "Pola yang Berkembang",
                text: insight.patterns,
                color: .orange
            )
            OverallInsightCard(
                icon: "scope",
                title: "Yang Sedang Menonjol",
                text: insight.recentFocus,
                color: .teal
            )

            Text("Diperbarui \(insight.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct OverallInsightCard: View {
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
