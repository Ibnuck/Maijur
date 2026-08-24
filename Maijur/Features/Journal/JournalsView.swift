import SwiftUI

struct JournalsView: View {
    let store: JournalStore

    @State private var editorRoute: EditorRoute?
    @State private var journalPendingDeletion: JournalEntry?

    var body: some View {
        Group {
            switch store.journalsPhase {
            case .loading:
                ProgressView("Loading Journals")
            case .loaded where store.journals.isEmpty:
                ContentUnavailableView {
                    Label("Belum Ada Jurnal", systemImage: "book.closed")
                } description: {
                    Text("Tuliskan pikiran, perasaan, atau hal yang ingin kamu ingat.")
                } actions: {
                    Button("Tulis Jurnal Pertama", systemImage: "square.and.pencil") {
                        editorRoute = .create
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .loaded:
                List {
                    Section {
                        NavigationLink {
                            OverallInsightView(store: store)
                        } label: {
                            OverallInsightRow(store: store)
                        }
                        .accessibilityIdentifier("overall-insight-link")
                    }

                    Section("Jurnalmu") {
                        ForEach(store.journals) { journal in
                            NavigationLink {
                                JournalDetailView(journal: journal, store: store) {
                                    editorRoute = .edit(journal)
                                }
                            } label: {
                                JournalRow(journal: journal)
                            }
                        }
                        .onDelete { offsets in
                            journalPendingDeletion = offsets.compactMap { store.journals[safe: $0] }.first
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .accessibilityIdentifier("journals-root-populated")
            }
        }
        .navigationTitle("Jurnal")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Jurnal Baru", systemImage: "square.and.pencil") {
                    editorRoute = .create
                }
                .accessibilityIdentifier("new-journal-button")
            }
        }
        .sheet(item: $editorRoute) { route in
            JournalEditorView(store: store, entry: route.entry)
        }
        .confirmationDialog(
            "Hapus jurnal ini?",
            isPresented: Binding(
                get: { journalPendingDeletion != nil },
                set: { if !$0 { journalPendingDeletion = nil } }
            ),
            presenting: journalPendingDeletion
        ) { journal in
            Button("Hapus Jurnal", role: .destructive) {
                store.deleteJournal(id: journal.id)
                journalPendingDeletion = nil
            }
        } message: { _ in
            Text("Jurnal ini akan dihapus dari perangkat ini.")
        }
    }
}

private struct OverallInsightRow: View {
    let store: JournalStore

    private var subtitle: String {
        let pendingCount = store.pendingOverallInsights.count
        if pendingCount > 0 { return "\(pendingCount) insight baru siap digabungkan" }
        if store.overallInsight != nil { return "Sudah mencakup insight terbaru" }
        return "Temukan pola dari insight jurnalmu"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .mint)
                .frame(width: 44, height: 44)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Insight Keseluruhan")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct JournalRow: View {
    let journal: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(journal.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(journal.text)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private enum EditorRoute: Identifiable {
    case create
    case edit(JournalEntry)

    var id: String {
        switch self {
        case .create:
            "create"
        case .edit(let entry):
            entry.id.uuidString
        }
    }

    var entry: JournalEntry? {
        guard case .edit(let entry) = self else { return nil }
        return entry
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview("Populated journals") {
    NavigationStack {
        JournalsView(store: MockData.populatedStore())
    }
}

#Preview("Empty journals") {
    NavigationStack {
        JournalsView(store: MockData.emptyStore())
    }
}

#Preview("Loading journals") {
    NavigationStack {
        JournalsView(store: MockData.loadingStore())
    }
}
