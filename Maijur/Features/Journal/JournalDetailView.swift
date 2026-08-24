import SwiftUI

struct JournalDetailView: View {
    let journal: JournalEntry
    let store: JournalStore
    let onEdit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(journal.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(journal.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("journal-detail-text")
                }
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
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                JournalInsightView(journal: journal, store: store)
            } label: {
                Label(
                    store.history.contains(where: {
                        $0.belongsToCurrentRevision(of: journal)
                            && $0.isCompatible(with: JournalAnalysisService.promptVersion)
                    })
                        ? "Buka Insight"
                        : "Buat Insight",
                    systemImage: "sparkles"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
            .accessibilityIdentifier("open-insights-button")
        }
    }
}

#Preview("Journal detail") {
    NavigationStack {
        JournalDetailView(journal: MockData.previewJournal, store: MockData.populatedStore(), onEdit: {})
    }
}
