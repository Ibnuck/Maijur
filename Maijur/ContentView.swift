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
        ZStack {
            NavigationStack {
                JournalsView(store: store)
            }

            if let persistenceError = store.persistenceError {
                MaiJurAlert(
                    symbol: "externaldrive.badge.exclamationmark",
                    tint: .orange,
                    title: "Perubahan belum tersimpan",
                    message: persistenceError,
                    primaryTitle: "Tutup",
                    primaryRole: nil,
                    primaryAction: store.clearPersistenceError
                )
                .zIndex(20)
            }
        }
    }
}

#Preview("Populated") {
    ContentView(store: MockData.populatedStore())
}

#Preview("Empty") {
    ContentView(store: MockData.emptyStore())
}
