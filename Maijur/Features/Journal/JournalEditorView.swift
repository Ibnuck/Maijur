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

    var body: some View {
        NavigationStack {
            Form {
                Section("Tanggal") {
                    DatePicker("Tanggal jurnal", selection: $draft.date, displayedComponents: .date)
                        .accessibilityIdentifier("journal-date-picker")
                }

                Section("Isi jurnal") {
                    TextEditor(text: $draft.text)
                        .focused($isWritingFocused)
                        .frame(minHeight: 220, alignment: .topLeading)
                        .accessibilityLabel("Isi jurnal")
                        .accessibilityIdentifier("journal-text-editor")
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
