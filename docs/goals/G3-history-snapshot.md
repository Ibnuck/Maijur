# G3 — Per-Journal Insight Snapshots

## Objective

Store generated output locally and make it available from the source journal's
dedicated Insight page.

## Tasks

- [ ] Define the insight snapshot model and source-journal relationship.
- [ ] Store summary, reflection, digest, date, revision, and coverage metadata.
- [ ] Add a local insight repository or data boundary.
- [ ] Connect the dedicated Insight UI to local snapshots.
- [ ] Preserve older snapshots when a journal is edited.
- [ ] Delete private derived snapshots when the source journal is deleted.
- [ ] Verify an existing insight remains readable without another model call.
- [ ] Create a fresh reviewer after each task and after the goal.

## Acceptance criteria

- An insight snapshot can be saved, opened from its journal, and read after
  relaunch.
- Each snapshot has a clear date and source journal relationship.
- Summary, reflection, and digest are displayed distinctly.
- Privacy behavior for edit and delete is deterministic.
