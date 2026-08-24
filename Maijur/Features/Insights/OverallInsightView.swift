import SwiftUI

struct OverallInsightView: View {
    let store: JournalStore

    @State private var isGenerating = false
    @State private var generationError: String?

    private var insight: OverallInsightSnapshot? { store.overallInsight }
    private var pendingCount: Int { store.pendingOverallInsights.count }

    var body: some View {
        ZStack {
            InsightPageBackground()

            ScrollView {
                VStack(spacing: 16) {
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
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(generationError != nil)
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
                .tint(.indigo)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
                .accessibilityIdentifier("create-overall-insight-button")
            }
        }
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
            generationError = InsightAlertCopy.message(for: error)
        }
    }
}

private struct OverallInsightHero: View {
    let hasResult: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.indigo.opacity(0.18), radius: 16, y: 7)
                .accessibilityHidden(true)

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
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 5)
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

            Text("Diperbarui \(insight.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
