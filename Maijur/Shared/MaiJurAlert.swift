import SwiftUI

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

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: symbol)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 58, height: 58)
                        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(spacing: 6) {
                        Text(title)
                            .font(.title3.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    if let journal {
                        JournalAlertPreview(journal: journal)
                    }
                }
                .padding(22)

                Divider()

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
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
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
                .frame(maxWidth: .infinity, minHeight: 52)
        }
    }
}

private struct JournalAlertPreview: View {
    let journal: JournalEntry

    var body: some View {
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
}

enum InsightAlertCopy {
    static func message(for error: Error) -> String {
        if let error = error as? JournalAnalysisError {
            return error.localizedDescription
        }
        if let error = error as? OverallInsightError {
            return error.localizedDescription
        }
        return "Model belum menghasilkan insight yang dapat digunakan. Jurnalmu tetap aman; silakan coba lagi."
    }
}
