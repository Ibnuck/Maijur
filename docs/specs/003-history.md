# Spec 003 — Per-Journal Insight Snapshots

## Goal

Persist generated insight locally so each journal can reopen its result without
running Foundation Models again. MaiJur does not expose a separate History tab.

## Snapshot model

Each snapshot contains:

- a stable identifier;
- source journal identifier, date, revision, and content hash;
- generation date;
- story essence (`summary`);
- reflection space (`reflection`);
- developing patterns (`digest`);
- represented journal identifiers;
- prompt and model versions when available.

## Behavior

- Summary and reflection use separate model sessions but are saved together.
- The latest developing-pattern value is retained as compact context for the
  next journal.
- The journal detail opens a dedicated Insight page; generated text never
  shares the journal editor screen.
- A completed insight for the current journal revision is reused rather than
  generated again.
- Editing a journal changes its content revision and allows a new matching
  insight to be created.
- Deleting a journal removes its private derived snapshots.
- Saved insight remains readable when Foundation Models is unavailable.

## UI boundary

The stored snapshot supports one journal's Insight page and future model
context. It is not a global user-facing archive and does not require an extra
tab, list, search, or export flow.

## Acceptance criteria

- A completed analysis creates one locally stored snapshot.
- The snapshot displays Inti Cerita, Ruang Refleksi, and Pola yang Berkembang.
- The snapshot reopens from its source journal after relaunch without another
  model call.
- The source journal revision relationship is deterministic.
- Deleting the source journal removes its derived private insight.
