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
                                        journalPendingDeletion = journal
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
        .sheet(item: $journalPendingDeletion) { journal in
            DeleteJournalSheet(
                journal: journal,
                hasInsight: hasCurrentInsight(for: journal),
                cancel: {
                    journalPendingDeletion = nil
                },
                delete: {
                    journalPendingDeletion = nil
                    store.deleteJournal(id: journal.id)
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
    }
}

private struct DeleteJournalSheet: View {
    let journal: JournalEntry
    let hasInsight: Bool
    let cancel: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash.fill")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.red)
                .frame(width: 64, height: 64)
                .background(Color.red.opacity(0.11), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(spacing: 7) {
                Text("Hapus jurnal ini?")
                    .font(.title2.weight(.bold))

                Text(hasInsight
                     ? "Jurnal dan insight terkait akan dihapus permanen dari perangkat ini."
                     : "Jurnal ini akan dihapus permanen dari perangkat ini.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 1) {
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
                .frame(width: 44)

                Rectangle()
                    .fill(Color.indigo.opacity(0.20))
                    .frame(width: 2, height: 60)

                Text(journal.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(spacing: 10) {
                Button(role: .destructive) {
                    delete()
                } label: {
                    Label("Hapus Jurnal", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .accessibilityIdentifier("confirm-delete-journal-button")

                Button(action: cancel) {
                    Text("Batalkan")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("cancel-delete-journal-button")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
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
