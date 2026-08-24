import SwiftUI

struct JournalsView: View {
    let store: JournalStore

    @State private var editorRoute: EditorRoute?
    @State private var journalPendingDeletion: JournalEntry?

    private var monthlySections: [JournalMonthSection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.journals) { journal in
            calendar.dateInterval(of: .month, for: journal.date)?.start ?? journal.date
        }

        return grouped
            .map { month, journals in
                JournalMonthSection(
                    month: month,
                    journals: journals.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.month > $1.month }
    }

    private func hasCurrentInsight(for journal: JournalEntry) -> Bool {
        store.history.contains {
            $0.belongsToCurrentRevision(of: journal)
                && $0.isCompatible(with: JournalAnalysisService.promptVersion)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

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
                        NavigationLink {
                            OverallInsightView(store: store)
                        } label: {
                            OverallInsightRow(store: store)
                        }
                        .tint(.white)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 18, trailing: 16))
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("overall-insight-link")
                    }

                    ForEach(monthlySections) { section in
                        Section {
                            ForEach(section.journals) { journal in
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
                                .listRowInsets(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 16))
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                                .alignmentGuide(.listRowSeparatorLeading) { _ in 68 }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Hapus", systemImage: "trash", role: .destructive) {
                                        withAnimation(.snappy(duration: 0.24)) {
                                            journalPendingDeletion = journal
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text(section.month.formatted(
                                .dateTime
                                    .month(.wide)
                                    .year()
                                    .locale(Locale(identifier: "id_ID"))
                            ))
                            .font(.headline)
                            .textCase(nil)
                            .foregroundStyle(.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .accessibilityIdentifier("journals-root-populated")
            }

            if let journal = journalPendingDeletion {
                DeleteJournalAlert(
                    journal: journal,
                    hasInsight: hasCurrentInsight(for: journal),
                    cancel: dismissDeleteAlert,
                    delete: {
                        dismissDeleteAlert()
                        store.deleteJournal(id: journal.id)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .zIndex(10)
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
    }

    private func dismissDeleteAlert() {
        withAnimation(.snappy(duration: 0.20)) {
            journalPendingDeletion = nil
        }
    }
}

private struct DeleteJournalAlert: View {
    let journal: JournalEntry
    let hasInsight: Bool
    let cancel: () -> Void
    let delete: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(width: 58, height: 58)
                        .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(spacing: 6) {
                        Text("Hapus jurnal ini?")
                            .font(.title3.weight(.bold))

                        Text(hasInsight
                             ? "Jurnal dan insight yang terhubung akan ikut dihapus."
                             : "Jurnal ini akan dihapus permanen dari perangkat.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 12) {
                        VStack(spacing: 0) {
                            Text(journal.date, format: .dateTime.day())
                                .font(.title3.weight(.bold))
                                .monospacedDigit()
                            Text(journal.date.formatted(
                                .dateTime
                                    .month(.abbreviated)
                                    .locale(Locale(identifier: "id_ID"))
                            ))
                                .font(.caption2.weight(.bold))
                                .textCase(.uppercase)
                                .foregroundStyle(.indigo)
                        }
                        .frame(width: 42)

                        Capsule()
                            .fill(Color.indigo.opacity(0.22))
                            .frame(width: 2, height: 46)

                        Text(journal.text)
                            .font(.subheadline)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(14)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(22)

                Divider()

                HStack(spacing: 0) {
                    Button("Batalkan", action: cancel)
                        .fontWeight(.semibold)
                        .foregroundStyle(.indigo)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .accessibilityIdentifier("cancel-delete-journal-button")

                    Divider()
                        .frame(height: 52)

                    Button(role: .destructive) {
                        delete()
                    } label: {
                        Text("Hapus")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("confirm-delete-journal-button")
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.20), radius: 30, y: 16)
            .padding(.horizontal, 30)
            .frame(maxWidth: 430)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
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
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Insight Keseluruhan")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(2)
            }
            .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
    }
}

private struct JournalRow: View {
    let journal: JournalEntry
    let hasInsight: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 2) {
                Text(journal.date, format: .dateTime.day())
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                Text(journal.date.formatted(
                    .dateTime
                        .weekday(.abbreviated)
                        .locale(Locale(identifier: "id_ID"))
                ))
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.indigo)
            }
            .frame(width: 42)

            Capsule()
                .fill(Color.indigo.opacity(0.22))
                .frame(width: 2, height: 58)

            VStack(alignment: .leading, spacing: 8) {
                Text(journal.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if hasInsight {
                    Label("Insight tersedia", systemImage: "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.indigo)
                }
            }
        }
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

private struct JournalMonthSection: Identifiable {
    let month: Date
    let journals: [JournalEntry]

    var id: Date { month }
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
