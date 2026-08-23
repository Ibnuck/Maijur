//
//  MaijurApp.swift
//  Maijur
//
//  Created by Ibnu Taufick Ahraza on 8/23/26.
//

import SwiftUI

@main
struct MaijurApp: App {
    @State private var store = MockData.populatedStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
