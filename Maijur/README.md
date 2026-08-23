# MaiJur Source Area

The Xcode project now exists. The default `MaijurApp.swift` and
`ContentView.swift` remain in the source root so the Xcode project references
stay intact. Their final feature placement can be handled as part of G1 after
the UI design is approved.

The first implementation goal is `docs/goals/G1-native-ui.md`.

```text
MaiJur/
├── App/                 App entry and dependency composition
├── Features/            User-facing feature areas
│   ├── Journal/
│   └── History/
├── Data/                SwiftData models and local repositories
├── AI/                  Foundation Models orchestration
└── Shared/              Small reusable UI and domain utilities
```
