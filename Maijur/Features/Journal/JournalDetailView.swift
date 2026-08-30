import SwiftUI

struct JournalDetailView: View {
    let journal: JournalEntry
    let store: JournalStore
    let onEdit: () -> Void

    private var hasCurrentInsight: Bool {
        store.history.contains {
            $0.belongsToCurrentRevision(of: journal)
                && $0.isCompatible(with: JournalAnalysisService.promptVersion)
                && $0.hasValidLanguageContract()
        }
    }

    var body: some View {
        ZStack {
            JournalDetailBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    JournalDetailDateHeader(date: journal.date)

                    JournalPage(text: journal.text)

                    NavigationLink {
                        JournalInsightView(journal: journal, store: store)
                    } label: {
                        JournalInsightCallout(hasInsight: hasCurrentInsight)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("open-insights-button")

                    Label("Jurnal dan insight tersimpan secara lokal di perangkat ini.", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
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
    }
}

#Preview("Journal detail") {
    NavigationStack {
        JournalDetailView(journal: MockData.previewJournal, store: MockData.populatedStore(), onEdit: {})
    }
}

private struct JournalDetailBackground: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
            Circle()
                .fill(Color.indigo.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: 100, y: -140)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct JournalDetailDateHeader: View {
    let date: Date
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date, format: .dateTime.weekday(.wide))
                        .font(.title3.weight(.semibold))
                    Text(date, format: .dateTime.day().month(.wide).year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                compactHeader
            }
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
    }

    private var compactHeader: some View {
        HStack(spacing: 14) {
            VStack(spacing: 1) {
                Text(date, format: .dateTime.day())
                    .font(.title.weight(.bold))
                Text(date, format: .dateTime.month(.abbreviated))
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.indigo)
            }
            .frame(width: 58, height: 58)
            .background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.title3.weight(.semibold))
                Text(date, format: .dateTime.month(.wide).day().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct JournalPage: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Catatanmu", systemImage: "book.pages")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.indigo)

            Divider()

            Text(text)
                .font(.body)
                .lineSpacing(7)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("journal-detail-text")
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 5)
    }
}

private struct JournalInsightCallout: View {
    let hasInsight: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: hasInsight ? "sparkles.rectangle.stack.fill" : "sparkles")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(hasInsight ? "Buka Insight" : "Temukan Insight")
                    .font(.headline)
                Text(hasInsight ? "Lihat kembali inti cerita dan ruang refleksimu." : "Temukan inti cerita, tema, dan ruang refleksi personal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.indigo.opacity(0.12), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(hasInsight ? "Buka Insight" : "Temukan Insight")
        .accessibilityValue(hasInsight ? "Insight jurnal ini sudah tersedia." : "Insight jurnal ini belum dibuat.")
        .accessibilityHint("Membuka halaman insight jurnal.")
    }
}
