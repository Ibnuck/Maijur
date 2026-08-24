import SwiftUI

struct HistoryView: View {
    let store: JournalStore

    var body: some View {
        Group {
            switch store.historyPhase {
            case .loading:
                ProgressView("Loading History")
            case .loaded where store.history.isEmpty:
                ContentUnavailableView {
                    Label("Belum Ada Riwayat", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Ringkasan dan refleksi yang tersimpan akan muncul di sini.")
                }
            case .loaded:
                List(store.history) { snapshot in
                    NavigationLink {
                        HistoryDetailView(snapshot: snapshot)
                    } label: {
                        HistoryRow(snapshot: snapshot)
                    }
                }
                .listStyle(.insetGrouped)
                .accessibilityIdentifier("history-root-populated")
            }
        }
        .navigationTitle("Riwayat")
    }
}

private struct HistoryRow: View {
    let snapshot: HistorySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(snapshot.createdAt, format: .dateTime.month(.abbreviated).day().year())
                .font(.subheadline.weight(.semibold))
            Text(snapshot.summary)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct HistoryDetailView: View {
    let snapshot: HistorySnapshot

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 52, height: 52)
                        .background(Color.accentColor.opacity(0.12), in: Circle())

                    Text("Insight Tersimpan")
                        .font(.title3.weight(.bold))

                    VStack(spacing: 6) {
                        LabeledContent("Tanggal jurnal") {
                            Text(snapshot.sourceJournalDate, format: .dateTime.month(.wide).day().year())
                        }
                        LabeledContent("Disimpan") {
                            Text(snapshot.createdAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                InsightResultCards(snapshot: snapshot)
            }
            .padding()
            .frame(maxWidth: 700)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Insight")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("History") {
    NavigationStack {
        HistoryView(store: MockData.populatedStore())
    }
}

#Preview("Empty history") {
    NavigationStack {
        HistoryView(store: MockData.emptyStore())
    }
}
