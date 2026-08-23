# Spec 003 — History Snapshots

## Goal

Persist generated summary, reflection, and digest results as dated snapshots
that the user can revisit without running Foundation Models again.

## Snapshot model

Each `HistoryItem` represents one completed analysis event and contains:

- stable identifier;
- source journal identifier;
- source journal date;
- source journal revision or content hash;
- generation date and time;
- summary text;
- reflection text;
- digest snapshot;
- IDs or date coverage for journals represented by the digest;
- prompt version and model version when available.

## Behavior

- Summary and reflection are generated in separate model sessions but saved as
  one user-visible History item.
- The latest digest is retained for future model context.
- Older History items remain readable as historical snapshots.
- Editing a journal does not silently rewrite an older snapshot. A new analysis
  produces a new snapshot linked to the new revision.
- Deleting a journal deletes derived History items by default because generated
  text may contain private information from that journal.
- History remains readable if Foundation Models later becomes unavailable.

## UI boundary

History is a user-facing archive, not the model's entire context. Future model
requests use the latest digest and the required new summary, not every History
item or every raw journal.

## Out of scope

- cloud backup or cross-device sync;
- manual editing of generated output;
- sharing, export, or search across History;
- automatic re-analysis after every keystroke.

## Acceptance criteria

- A completed analysis creates one dated History snapshot.
- The snapshot displays summary, reflection, and digest clearly.
- The snapshot can be opened after relaunch without another model call.
- The source journal and revision relationship is inspectable by the app.
- Deleting a source journal removes its derived private insight snapshots.
