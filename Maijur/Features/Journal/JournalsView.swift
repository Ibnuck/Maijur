import SwiftUI

struct JournalsView: View {
    let store: JournalStore

    @State private var editorRoute: EditorRoute?
    @State private var journalPendingDeletion: JournalEntry?

    private func hasCurrentInsight(for journal: JournalEntry) -> Bool {
        store.history.contains {
            $0.belongsToCurrentRevision(of: journal)
                && $0.isCompatible(with: JournalAnalysisService.promptVersion)
        }
    }

    var body: some View {
        ZStack {
            JournalsBackground()

            switch store.journalsPhase {
            case .loading:
                JournalsLoadingState()
            case .loaded where store.journals.isEmpty:
                JournalsEmptyState {
                    editorRoute = .create
                }
            case .loaded:
                List {
                    Section {
                        JournalLibraryHeader(journalCount: store.journals.count)
                            .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 12, trailing: 18))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                        NavigationLink {
                            OverallInsightView(store: store)
                        } label: {
                            OverallInsightRow(store: store)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("overall-insight-link")
                    }

                    Section {
                        ForEach(store.journals) { journal in
                            NavigationLink {
                                JournalDetailView(journal: journal, store: store) {
                                    editorRoute = .edit(journal)
                                }
                            } label: {
                                JournalRow(
                                    journal: journal,
                                    hasInsight: hasCurrentInsight(for: journal)
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .padding(.vertical, 3)
                            )
                            .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            journalPendingDeletion = offsets.compactMap { store.journals[safe: $0] }.first
                        }
                    } header: {
                        HStack {
                            Text("Catatan terbaru")
                            Spacer()
                            Text(store.journals.count, format: .number)
                                .monospacedDigit()
                        }
                        .font(.subheadline.weight(.semibold))
                        .textCase(nil)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .accessibilityIdentifier("journals-root-populated")
            }
        }
        .navigationTitle("Jurnal")
        .navigationBarTitleDisplayMode(.large)
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Gambaran Besarmu")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
    }
}

private struct JournalRow: View {
    let journal: JournalEntry
    let hasInsight: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 1) {
                Text(journal.date, format: .dateTime.day())
                    .font(.title3.weight(.bold))
                Text(journal.date, format: .dateTime.month(.abbreviated))
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.indigo)
            }
            .frame(width: 48, height: 50)
            .background(Color.indigo.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(journal.date, format: .dateTime.weekday(.wide))
                    .font(.subheadline.weight(.semibold))

                Text(journal.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if hasInsight {
                    Label("Insight tersedia", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.indigo)
                }
            }
        }
        .padding(.vertical, 10)
    }
}

private struct JournalLibraryHeader: View {
    let journalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cerita yang kamu pilih untuk disimpan.")
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Label("\(journalCount) jurnal", systemImage: "book.pages.fill")
                Label("Tersimpan lokal", systemImage: "lock.fill")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }
}

private struct JournalsBackground: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
            Circle()
                .fill(Color.indigo.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 55)
                .offset(x: 130, y: -170)
        }
        .ignoresSafeArea()
    }
}

private struct JournalsLoadingState: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Membuka jurnalmu…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memuat jurnal")
    }
}

private struct JournalsEmptyState: View {
    let createJournal: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.indigo.opacity(0.18), radius: 18, y: 8)

            VStack(spacing: 8) {
                Text("Mulai halaman pertamamu")
                    .font(.title2.weight(.bold))
                Text("Tuliskan hal yang memenuhi pikiranmu hari ini. Tidak harus panjang atau sempurna.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: createJournal) {
                Label("Tulis Jurnal", systemImage: "square.and.pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: 440)
        .accessibilityIdentifier("journals-root-empty")
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
