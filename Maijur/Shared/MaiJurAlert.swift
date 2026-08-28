import SwiftUI
import Translation

struct MaiJurAlert: View {
    let symbol: String
    let tint: Color
    let title: String
    let message: String
    let primaryTitle: String
    let primaryRole: ButtonRole?
    let primaryAction: () -> Void
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?
    var journal: JournalEntry?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var isTitleFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                alertContent
                    .padding(22)

                Divider()

                alertActions
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.20), radius: 30, y: 16)
            .padding(.horizontal, 30)
            .padding(.vertical, 24)
            .frame(maxWidth: 430)
            .fixedSize(horizontal: false, vertical: true)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) {
            if let secondaryAction {
                secondaryAction()
            } else {
                primaryAction()
            }
        }
        .onAppear {
            isTitleFocused = true
        }
    }

    @ViewBuilder
    private var alertContent: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                alertContentStack
            }
            .frame(maxHeight: 360)
        } else {
            alertContentStack
        }
    }

    private var alertContentStack: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 58, height: 58)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let journal {
                JournalAlertPreview(journal: journal)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var alertActions: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 0) {
                if let secondaryTitle, let secondaryAction {
                    alertButton(
                        title: secondaryTitle,
                        color: .indigo,
                        role: .cancel,
                        action: secondaryAction
                    )
                    Divider()
                }

                alertButton(
                    title: primaryTitle,
                    color: primaryRole == .destructive ? .red : .indigo,
                    role: primaryRole,
                    action: primaryAction
                )
            }
        } else {
            HStack(spacing: 0) {
                if let secondaryTitle, let secondaryAction {
                    alertButton(
                        title: secondaryTitle,
                        color: .indigo,
                        role: .cancel,
                        action: secondaryAction
                    )

                    Divider()
                        .frame(height: 52)
                }

                alertButton(
                    title: primaryTitle,
                    color: primaryRole == .destructive ? .red : .indigo,
                    role: primaryRole,
                    action: primaryAction
                )
            }
        }
    }

    private func alertButton(
        title: String,
        color: Color,
        role: ButtonRole?,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Text(title)
                .fontWeight(role == .destructive ? .bold : .semibold)
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 8)
        }
    }
}

private struct JournalAlertPreview: View {
    let journal: JournalEntry
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.indigo)
                    previewText
                }
            } else {
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

                    previewText
                }
            }
        }
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(formattedDate). \(journal.text)")
    }

    private var previewText: some View {
        Text(journal.text)
            .font(.subheadline)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedDate: String {
        journal.date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(Locale(identifier: "id_ID"))
        )
    }
}

enum InsightAlertCopy {
    static func message(for error: Error) -> String {
        if let error = error as? JournalAnalysisError {
            return error.localizedDescription
        }
        if let error = error as? OverallInsightError {
            return error.localizedDescription
        }
        if let error = error as? InsightTranslationError {
            return error.localizedDescription
        }
        if error is TranslationError {
            return "Bahasa ini belum siap diterjemahkan di iPhone. Pastikan paket bahasanya tersedia, lalu coba lagi."
        }
        return "Model belum menghasilkan insight yang dapat digunakan. Jurnalmu tetap aman; silakan coba lagi."
    }
}
