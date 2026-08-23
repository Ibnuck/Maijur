//
//  ContentView.swift
//  Maijur
//
//  Created by Ibnu Taufick Ahraza on 8/23/26.
//

import SwiftUI

struct ContentView: View {
    let store: MockJournalStore

    var body: some View {
        TabView {
            NavigationStack {
                journalsRoot
                    .navigationTitle("Journals")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("New Journal", systemImage: "square.and.pencil") {}
                                .accessibilityLabel("New Journal")
                                .accessibilityIdentifier("new-journal-button")
                        }
                    }
            }
            .tabItem {
                Label("Journals", systemImage: "book.closed")
                    .accessibilityIdentifier("journals-tab")
            }

            NavigationStack {
                historyRoot
                    .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .accessibilityIdentifier("history-tab")
            }
        }
    }

    @ViewBuilder
    private var journalsRoot: some View {
        switch store.journalsPhase {
        case .loading:
            ProgressView("Loading Journals")
        case .loaded where store.journals.isEmpty:
            ContentUnavailableView(
                "No Journals",
                systemImage: "book.closed",
                description: Text("New journal entries will appear here.")
            )
        case .loaded:
            List(store.journals) { journal in
                Text(journal.text)
                    .lineLimit(2)
            }
            .accessibilityIdentifier("journals-root-populated")
        }
    }

    @ViewBuilder
    private var historyRoot: some View {
        switch store.historyPhase {
        case .loading:
            ProgressView("Loading History")
        case .loaded where store.history.isEmpty:
            ContentUnavailableView(
                "No History",
                systemImage: "clock.arrow.circlepath",
                description: Text("Insight snapshots will appear here.")
            )
        case .loaded:
            List(store.history) { snapshot in
                Text(snapshot.summary)
                    .lineLimit(2)
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
