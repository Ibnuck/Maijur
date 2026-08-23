# Spec 002 — Local Journaling CRUD

## Goal

Replace mock journal data with local device persistence while preserving the
UI flow established by the native UI goal.

## Behavior

- Create a journal with content and date.
- Read journals sorted by the user's journal date, with a stable tie-breaker.
- Edit content and date without losing the journal identity.
- Delete a journal through a native confirmation affordance.
- Persist data without an account or server.
- Keep the app usable when the persistent store cannot be opened; expose a
  clear recoverable state rather than silently losing input.

## Data boundary

The UI communicates with a small local data boundary. Views should not contain
SwiftData fetch, save, or delete orchestration directly.

The journal record needs at least:

- stable identifier;
- journal date;
- creation and modification timestamps;
- content;
- revision or content hash used to identify changes relevant to AI analysis.

## Out of scope

- cloud sync;
- user accounts;
- search, tags, attachments, or reminders;
- AI generation.

## Acceptance criteria

- CRUD survives app relaunch on the target device or simulator.
- Editing preserves the correct record and updates modification metadata.
- Deleting requires an intentional user action.
- No journal content is sent to a server.
- Existing UI previews remain deterministic and do not depend on the store.
