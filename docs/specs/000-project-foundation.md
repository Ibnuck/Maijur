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

## Planned source boundaries

```text
MaiJur/
├── App/         App entry and dependency composition
├── Features/    User-facing feature areas
├── Data/        SwiftData models and local repositories
├── AI/          Foundation Models sessions and output mapping
└── Shared/      Small reusable UI and domain utilities
```

These are boundaries, not a requirement to create a layer or protocol for
every file.

## Acceptance criteria

- Root agent rules exist in `AGENTS.md`.
- Xcode and Swift generated files are excluded without hiding source,
  documentation, or intentional project configuration.
- The engineering loop defines brainstormer, implementer, and fresh reviewer
  responsibilities.
- Goals are ordered with native UI before persistence and AI.
- The source skeleton does not contain premature feature implementation.
