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
                    VStack(spacing: 14) {
                        JournalDateRow(date: $draft.date)

                        JournalWritingSurface(
                            text: limitedText,
                            characterCount: draft.characterCount,
                            remainingCount: draft.remainingCharacterCount,
                            progress: draft.characterLimitProgress,
                            isFocused: $isWritingFocused
                        )

                        Label("Jurnalmu tersimpan secara lokal di perangkat ini.", systemImage: "lock.fill")
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
            }
            .navigationTitle(entry == nil ? "Jurnal Baru" : "Edit Jurnal")
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
                    .disabled(!draft.isValid)
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
    }
}

private struct JournalDateRow: View {
    @Binding var date: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.body.weight(.semibold))
                .foregroundStyle(.indigo)
                .frame(width: 38, height: 38)
                .background(Color.indigo.opacity(0.10), in: Circle())

            Text("Tanggal jurnal")
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 8)

            DatePicker("Tanggal jurnal", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .accessibilityLabel("Tanggal jurnal")
                .accessibilityIdentifier("journal-date-picker")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct JournalWritingSurface: View {
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
        return "Maks. \(JournalDraft.maximumCharacterCount.formatted())"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Apa yang ingin kamu simpan hari ini?")
                    .font(.title2.weight(.bold))
                Text("Tidak perlu sempurna—cukup tulis apa yang sedang ada di pikiranmu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Mulai menulis…")
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

            HStack(spacing: 12) {
                ProgressView(value: progress)
                    .tint(meterColor)
                    .frame(maxWidth: .infinity)
                    .animation(.easeOut(duration: 0.2), value: progress)

                Text("\(characterCount.formatted()) karakter")
                    .monospacedDigit()
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(meterMessage)
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
}
