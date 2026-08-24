import SwiftUI

struct JournalEditorView: View {
    let store: JournalStore
    let entry: JournalEntry?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isWritingFocused: Bool
    @State private var draft: JournalDraft
    @State private var showsDiscardConfirmation = false

    init(store: JournalStore, entry: JournalEntry? = nil) {
        self.store = store
        self.entry = entry
        if let entry {
            _draft = State(initialValue: JournalDraft(entry: entry))
        } else {
            _draft = State(initialValue: JournalDraft(date: .now, text: ""))
        }
    }

    private var hasChanges: Bool {
        if let entry {
            draft.isDirty(comparedTo: entry)
        } else {
            draft.isValid || !Calendar.current.isDateInToday(draft.date)
        }
    }

    private var canSave: Bool {
        draft.isValid && (entry == nil || hasChanges)
    }

    private var copy: JournalEditorCopy {
        entry == nil ? .create : .edit
    }

    private var limitedText: Binding<String> {
        Binding(
            get: { draft.text },
            set: { draft.updateText($0) }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                JournalEditorBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        JournalDateRow(date: $draft.date)

                        JournalWritingSurface(
                            text: limitedText,
                            characterCount: draft.characterCount,
                            remainingCount: draft.remainingCharacterCount,
                            progress: draft.characterLimitProgress,
                            title: copy.writingTitle,
                            placeholder: copy.placeholder,
                            isFocused: $isWritingFocused
                        )

                        Label(copy.privacyNote, systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(copy.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        requestDismissal()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                    .accessibilityIdentifier("save-journal-button")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Text("\(draft.characterCount.formatted()) / \(JournalDraft.maximumCharacterCount.formatted())")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Selesai") {
                        isWritingFocused = false
                    }
                }
            }
        }
        .accessibilityHidden(showsDiscardConfirmation)
        .interactiveDismissDisabled(hasChanges)
        .overlay {
            if showsDiscardConfirmation {
                MaiJurAlert(
                    symbol: "arrow.uturn.backward.circle.fill",
                    tint: .red,
                    title: copy.discardTitle,
                    message: copy.discardMessage,
                    primaryTitle: "Buang",
                    primaryRole: .destructive,
                    primaryAction: dismiss.callAsFunction,
                    secondaryTitle: "Lanjut Menulis",
                    secondaryAction: {
                        showsDiscardConfirmation = false
                    }
                )
            }
        }
    }

    private func requestDismissal() {
        hasChanges ? (showsDiscardConfirmation = true) : dismiss()
    }

    private func save() {
        let saved: JournalEntry?
        if let entry {
            saved = store.updateJournal(id: entry.id, date: draft.date, text: draft.text)
        } else {
            saved = store.createJournal(date: draft.date, text: draft.text)
        }
        if saved != nil {
            dismiss()
        }
    }
}

#Preview("Create journal") {
    JournalEditorView(store: MockData.emptyStore())
}

#Preview("Edit journal") {
    JournalEditorView(store: MockData.populatedStore(), entry: MockData.previewJournal)
}

private struct JournalEditorBackground: View {
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

private struct JournalDateRow: View {
    @Binding var date: Date
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    dateLabel
                    datePicker
                }
            } else {
                HStack(spacing: 12) {
                    dateLabel
                    Spacer(minLength: 8)
                    datePicker
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dateLabel: some View {
        Label {
            Text("Tanggal jurnal")
                .font(.subheadline.weight(.semibold))
        } icon: {
            Image(systemName: "calendar")
                .font(.body.weight(.semibold))
                .foregroundStyle(.indigo)
                .frame(width: 38, height: 38)
                .background(Color.indigo.opacity(0.10), in: Circle())
        }
    }

    private var datePicker: some View {
        DatePicker("Tanggal jurnal", selection: $date, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            .accessibilityLabel("Tanggal jurnal")
            .accessibilityIdentifier("journal-date-picker")
    }
}

private struct JournalWritingSurface: View {
    @Binding var text: String
    let characterCount: Int
    let remainingCount: Int
    let progress: Double
    let title: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var meterColor: Color {
        if progress >= 1 { return .red }
        if progress >= 0.85 { return .orange }
        return .indigo
    }

    private var meterMessage: String {
        if progress >= 1 { return "Batas tercapai" }
        if progress >= 0.85 { return "\(remainingCount.formatted()) tersisa" }
        return "Maks. \(JournalDraft.maximumCharacterCount.formatted())"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.weight(.bold))

            Divider()

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 9)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .focused(isFocused)
                    .font(.body)
                    .lineSpacing(7)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 390, alignment: .topLeading)
                    .accessibilityLabel("Isi jurnal")
                    .accessibilityHint("Maksimal \(JournalDraft.maximumCharacterCount) karakter")
                    .accessibilityIdentifier("journal-text-editor")
            }

            Divider()

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        characterProgress
                        characterSummary
                    }
                } else {
                    HStack(spacing: 12) {
                        characterProgress
                        characterSummary
                    }
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(meterColor)
            .contentTransition(.numericText())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Penggunaan karakter")
            .accessibilityValue("\(characterCount) dari \(JournalDraft.maximumCharacterCount), \(remainingCount) tersisa")
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 5)
    }

    private var characterProgress: some View {
        ProgressView(value: progress)
            .tint(meterColor)
            .frame(maxWidth: .infinity)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: progress)
    }

    private var characterSummary: some View {
        HStack(spacing: 6) {
            Text("\(characterCount.formatted()) karakter")
                .monospacedDigit()
            Text("•")
                .foregroundStyle(.tertiary)
            Text(meterMessage)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct JournalEditorCopy {
    let navigationTitle: String
    let writingTitle: String
    let placeholder: String
    let privacyNote: String
    let discardTitle: String
    let discardMessage: String

    static let create = JournalEditorCopy(
        navigationTitle: "Jurnal Baru",
        writingTitle: "Apa yang ingin kamu simpan?",
        placeholder: "Tulis pikiran, perasaan, atau kejadian yang ingin kamu ingat…",
        privacyNote: "Jurnal ini hanya tersimpan di perangkatmu.",
        discardTitle: "Buang jurnal baru?",
        discardMessage: "Tulisan yang belum disimpan akan hilang."
    )

    static let edit = JournalEditorCopy(
        navigationTitle: "Edit Jurnal",
        writingTitle: "Perbarui ceritamu",
        placeholder: "Tulis ulang bagian yang ingin kamu ubah…",
        privacyNote: "Perubahan tetap tersimpan hanya di perangkatmu.",
        discardTitle: "Buang perubahan?",
        discardMessage: "Jurnal akan kembali ke versi terakhir yang disimpan."
    )
}
