# G1 — Native UI Foundation

**Status:** Complete

## Objective

Deliver the native visual flow and reusable UI states that later persistence
and Foundation Models work can use. Deterministic mock data remains available
for previews and tests.

## Tasks

- [x] Create the Xcode SwiftUI app shell and confirm the target configuration.
- [x] Use Journals as the single root destination.
- [x] Define mock journal data for previews and deterministic UI inspection.
- [x] Build populated and empty Journals states.
- [x] Build the journal editor with date, text input, and character feedback.
- [x] Build journal detail with edit and delete affordances.
- [x] Build dedicated per-journal and overall Insight pages.
- [x] Build empty, loading, result, unavailable, and error states for insights.
- [x] Add native navigation, accessible labels, and stable UI-test identifiers.

Dynamic Type, VoiceOver, contrast, and touch-target validation remain part of
G5 rather than blocking the UI foundation.

## Explicit non-goals

- SwiftData or any real persistence;
- Foundation Models calls;
- accounts, sync, settings, search, tags, attachments, and notifications;
- custom design system or third-party UI package.

## Acceptance criteria

- The user can understand the app's purpose from the initial screen.
- The user can navigate from Journals to journal detail, editor, per-journal
  Insight, and Overall Insight.
- Create, read, edit, and delete flows can be inspected with mock or in-memory
  data.
- The UI remains usable in empty, populated, and unavailable-insight states.
- The visual design uses native Apple components and scalable system text.
- The UI can be reviewed without a network connection or a persistent store.
