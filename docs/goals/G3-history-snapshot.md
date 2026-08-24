# G3 — Per-Journal Insight Snapshots

**Status:** Complete

## Objective

Store generated output locally and make it available from the source journal's
dedicated Insight page.

## Tasks

- [x] Define the insight snapshot model and source-journal relationship.
- [x] Store summary, reflection, themes, date, revision, and coverage metadata.
- [x] Keep snapshot persistence behind `JournalStore`.
- [x] Connect the dedicated Insight UI to local snapshots.
- [x] Reuse the saved insight for the current journal revision.
- [x] Delete the outdated insight when its source journal is edited.
- [x] Invalidate Overall Insight when it covers an insight removed by edit or
  delete.
- [x] Delete private derived insight when the source journal is deleted.
- [x] Verify an existing current-revision insight remains readable without
  another model call.

## Acceptance criteria

- An insight snapshot can be saved, opened from its journal, and read after
  relaunch.
- Each snapshot has a clear date and source journal relationship.
- Summary, reflection, and themes are displayed distinctly.
- Privacy behavior for edit and delete is deterministic.

The accepted lifecycle is documented in
`docs/decisions/0002-insight-lifecycle.md`.
