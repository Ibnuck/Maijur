//
//  ContentView.swift
//  Maijur
//
//  Created by Ibnu Taufick Ahraza on 8/23/26.
//

import SwiftUI

struct ContentView: View {
    let store: JournalStore

    var body: some View {
        NavigationStack {
            JournalsView(store: store)
        }
        .alert(
            "Jurnal Tidak Dapat Disimpan",
            isPresented: Binding(
                get: { store.persistenceError != nil },
                set: { if !$0 { store.clearPersistenceError() } }
            )
        ) {
            Button("Mengerti", role: .cancel) {
                store.clearPersistenceError()
            }
        } message: {
            Text(store.persistenceError ?? "Silakan coba lagi.")
        }
    }
}

#Preview("Populated") {
    ContentView(store: MockData.populatedStore())
}

#Preview("Empty") {
    ContentView(store: MockData.emptyStore())
}
