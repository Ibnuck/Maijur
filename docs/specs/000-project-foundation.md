# Spec 000 — Project Foundation

## Purpose

Create a small, understandable foundation for MaiJur before application
features are implemented.

## Product boundary

MaiJur is a local-first iPhone journaling app. The initial product supports:

- creating, reading, editing, and deleting journal entries;
- viewing each journal's generated story essence, reflection, and developing
  patterns from that journal's detail flow;
- optional on-device Foundation Models processing when the device and model are
  available.

The initial product does not include accounts, server sync, social features,
analytics, cloud backup, subscriptions, or a custom backend.

## Technical direction

- SwiftUI for the interface.
- SwiftData for local persistence when the persistence goal begins.
- Foundation Models for on-device language generation when the AI goal begins.
- Swift concurrency for asynchronous model and persistence work.
- Native Apple controls, navigation, typography, and accessibility behavior.
- No third-party dependency unless a later decision records a strong reason.

## Current source boundaries

```text
MaiJur/
├── App/         Store composition and deterministic mock data
├── Features/
│   ├── Journal/ Journal domain, SwiftData record, editor, list, and detail
│   ├── Insights/Foundation Models services, stored outputs, and Insight UI
│   └── History/ Per-journal insight snapshot storage types
└── Shared/      Small reusable UI and domain utilities
```

The project intentionally keeps these concrete boundaries small instead of
adding repository protocols or layers without a second implementation.

## Acceptance criteria

- Root agent rules exist in `AGENTS.md`.
- Xcode and Swift generated files are excluded without hiding source,
  documentation, or intentional project configuration.
- The engineering loop defines brainstormer, implementer, and fresh reviewer
  responsibilities.
- Goals are ordered with native UI before persistence and AI.
- The source skeleton does not contain premature feature implementation.
