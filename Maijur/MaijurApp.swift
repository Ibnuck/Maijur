//
//  MaijurApp.swift
//  Maijur
//
//  Created by Ibnu Taufick Ahraza on 8/23/26.
//

import SwiftUI
import SwiftData

@main
struct MaijurApp: App {
    private let modelContainer: ModelContainer?
    @State private var store: JournalStore

    init() {
        do {
            let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
            let container = try ModelContainer(
                for: StoredJournal.self,
                StoredHistorySnapshot.self,
                StoredOverallInsight.self,
                configurations: configuration
            )
            modelContainer = container
            _store = State(initialValue: JournalStore(modelContext: container.mainContext))
        } catch {
            modelContainer = nil
            _store = State(initialValue: JournalStore.unavailable(message: "MaiJur tidak dapat membuka penyimpanan lokal. Tutup lalu buka kembali aplikasi dan coba lagi."))
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                ContentView(store: store)
                    .modelContainer(modelContainer)
            } else {
                ContentView(store: store)
            }
        }
    }
}
