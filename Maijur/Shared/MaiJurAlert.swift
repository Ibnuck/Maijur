import FoundationModels
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

struct InsightAlertPresentation {
    let symbol: String
    let tint: Color
    let title: String
    let message: String
}

enum InsightAlertCopy {
    static func presentation(
        for error: Error,
        defaultTitle: String = "Insight belum dapat dibuat",
        defaultSymbol: String = "sparkles"
    ) -> InsightAlertPresentation {
        if let error = error as? LanguageModelSession.GenerationError,
           isSafetyRejection(error) {
            return InsightAlertPresentation(
                symbol: "exclamationmark.shield.fill",
                tint: .orange,
                title: "Konten dibatasi",
                message: generationMessage(for: error)
            )
        }

        return InsightAlertPresentation(
            symbol: defaultSymbol,
            tint: .indigo,
            title: defaultTitle,
            message: message(for: error)
        )
    }

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
        if let error = error as? LanguageModelSession.GenerationError {
            return generationMessage(for: error)
        }
        if error is TranslationError {
            return translationMessage(for: error)
        }
        if error is CancellationError {
            return "Proses pembuatan insight dibatalkan. Silakan coba lagi."
        }
        return "Model belum menghasilkan insight yang dapat digunakan. Jurnalmu tetap aman; silakan coba lagi."
    }

    private static func generationMessage(
        for error: LanguageModelSession.GenerationError
    ) -> String {
        switch error {
        case .exceededContextWindowSize:
            "Bahan insight terlalu panjang untuk diproses sekaligus. Jurnalmu tetap aman; coba ringkas isinya lalu buat insight lagi."
        case .assetsUnavailable:
            "Model Apple Intelligence belum siap di iPhone. Tunggu hingga proses penyiapan selesai, lalu coba lagi."
        case .guardrailViolation, .refusal:
            "Isi jurnal ini belum dapat diproses karena dibatasi oleh sistem keamanan Apple Intelligence. Jurnalmu tetap aman dan tersimpan."
        case .unsupportedGuide:
            "Format insight belum didukung oleh model di iPhone ini. Coba lagi setelah perangkat diperbarui."
        case .unsupportedLanguageOrLocale:
            "Bahasa untuk memproses insight belum didukung di iPhone ini. Coba tambahkan detail dengan bahasa yang didukung."
        case .decodingFailure:
            "Model belum menghasilkan format insight yang sesuai. Silakan coba lagi."
        case .rateLimited:
            "Model sedang sibuk. Tunggu sebentar, lalu coba buat insight lagi."
        case .concurrentRequests:
            "Insight lain masih sedang diproses. Tunggu hingga selesai, lalu coba lagi."
        @unknown default:
            "Model belum menghasilkan insight yang dapat digunakan. Jurnalmu tetap aman; silakan coba lagi."
        }
    }

    private static func isSafetyRejection(
        _ error: LanguageModelSession.GenerationError
    ) -> Bool {
        switch error {
        case .guardrailViolation, .refusal:
            true
        default:
            false
        }
    }

    private static func translationMessage(for error: Error) -> String {
        if TranslationError.notInstalled ~= error {
            return "Paket bahasa yang diperlukan belum terpasang di iPhone. Pasang paket bahasanya, lalu coba lagi."
        }
        if TranslationError.unableToIdentifyLanguage ~= error {
            return "Bahasa jurnal belum dapat dikenali. Coba tambahkan sedikit detail lalu buat insight lagi."
        }
        if TranslationError.nothingToTranslate ~= error {
            return "Tidak ada isi jurnal yang dapat diterjemahkan. Tambahkan sedikit cerita lalu coba lagi."
        }
        if TranslationError.unsupportedSourceLanguage ~= error
            || TranslationError.unsupportedTargetLanguage ~= error
            || TranslationError.unsupportedLanguagePairing ~= error {
            return "Pasangan bahasa ini belum didukung untuk membuat insight di iPhone."
        }
        if TranslationError.alreadyCancelled ~= error {
            return "Proses penerjemahan dibatalkan. Silakan coba lagi."
        }
        return "Terjemahan belum dapat diselesaikan di iPhone. Jurnalmu tetap aman; silakan coba lagi."
    }
}
