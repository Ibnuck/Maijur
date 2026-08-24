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
        _draft = State(initialValue: entry.map(JournalDraft.init(entry:)) ?? JournalDraft(date: .now, text: ""))
    }

    private var hasChanges: Bool {
        if let entry {
            draft.isDirty(comparedTo: entry)
        } else {
            draft.isValid || !Calendar.current.isDateInToday(draft.date)
        }
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
                    VStack(spacing: 18) {
                        JournalEditorHeader(date: $draft.date, isNewEntry: entry == nil)

                        JournalWritingCard(
                            text: limitedText,
                            characterCount: draft.characterCount,
                            remainingCount: draft.remainingCharacterCount,
                            progress: draft.characterLimitProgress,
                            isFocused: $isWritingFocused
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(entry == nil ? "Jurnal Baru" : "Edit Jurnal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") {
                        requestDismissal()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Selesai") {
                        isWritingFocused = false
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                JournalSaveBar(isEnabled: draft.isValid, isEditing: entry != nil, save: save)
            }
            .confirmationDialog(
                "Buang perubahan?",
                isPresented: $showsDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button("Buang Perubahan", role: .destructive) {
                    dismiss()
                }
                Button("Lanjut Menulis", role: .cancel) {}
            } message: {
                Text("Perubahan yang belum disimpan akan hilang.")
            }
            .onAppear {
                isWritingFocused = true
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
        LinearGradient(
            colors: [
                Color.indigo.opacity(0.10),
                Color.cyan.opacity(0.05),
                Color(.systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct JournalEditorHeader: View {
    @Binding var date: Date
    let isNewEntry: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: isNewEntry ? "pencil.and.scribble" : "book.pages.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(isNewEntry ? "Satu halaman untuk hari ini" : "Kembali ke ceritamu")
                        .font(.headline)
                    Text("Tulis apa adanya. Halaman ini hanya milikmu.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Label("Tanggal cerita", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                DatePicker(
                    "Tanggal jurnal",
                    selection: $date,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .accessibilityLabel("Tanggal jurnal")
                .accessibilityIdentifier("journal-date-picker")
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.indigo.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct JournalWritingCard: View {
    @Binding var text: String
    let characterCount: Int
    let remainingCount: Int
    let progress: Double
    var isFocused: FocusState<Bool>.Binding

    private var meterColor: Color {
        if progress >= 1 { return .red }
        if progress >= 0.85 { return .orange }
        return .blue
    }

    private var meterMessage: String {
        if progress >= 1 { return "Batas tercapai" }
        if progress >= 0.85 { return "\(remainingCount.formatted()) tersisa" }
        if characterCount == 0 { return "Mulai dari hal kecil" }
        return "Masih ada ruang"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Label("Ruang menulis", systemImage: "text.alignleft")
                    .font(.headline)
                    .foregroundStyle(.indigo)

                Spacer()

                Text(characterCount == 0 ? "Hari ini" : "Sedang ditulis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(characterCount == 0 ? Color.secondary : Color.indigo)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apa yang ingin kamu simpan dari hari ini?")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("Pikiran, perasaan, kejadian kecil, atau sesuatu yang kamu syukuri…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 9)
                    .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .focused(isFocused)
                    .font(.body)
                    .lineSpacing(7)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 330, alignment: .topLeading)
                    .accessibilityLabel("Isi jurnal")
                    .accessibilityHint("Maksimal \(JournalDraft.maximumCharacterCount) karakter")
                    .accessibilityIdentifier("journal-text-editor")
            }

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(meterColor)
                    .animation(.easeOut(duration: 0.2), value: progress)

                HStack {
                    Text("\(characterCount.formatted()) / \(JournalDraft.maximumCharacterCount.formatted()) karakter")
                        .monospacedDigit()
                    Spacer()
                    Text(meterMessage)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(meterColor)
                .contentTransition(.numericText())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Penggunaan karakter")
            .accessibilityValue("\(characterCount) dari \(JournalDraft.maximumCharacterCount), \(remainingCount) tersisa")

            Label(
                "Batas ini menjaga ruang yang cukup untuk menghasilkan insight yang lebih utuh.",
                systemImage: "sparkles"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: Color.indigo.opacity(0.06), radius: 18, y: 8)
    }
}

private struct JournalSaveBar: View {
    let isEnabled: Bool
    let isEditing: Bool
    let save: () -> Void

    var body: some View {
        Button(action: save) {
            Label(isEditing ? "Simpan Perubahan" : "Simpan Jurnal", systemImage: "checkmark")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!isEnabled)
        .accessibilityIdentifier("save-journal-button")
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
