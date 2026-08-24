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
        List {
            Section {
                LabeledContent("Tanggal jurnal") {
                    Text(snapshot.sourceJournalDate, format: .dateTime.month(.wide).day().year())
                }
                LabeledContent("Disimpan") {
                    Text(snapshot.createdAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                }
            }

            Section("Ringkasan") {
                Text(snapshot.summary)
            }
            Section("Refleksi") {
                Text(snapshot.reflection)
            }
            Section("Rangkuman") {
                Text(snapshot.digest)
            }
        }
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
