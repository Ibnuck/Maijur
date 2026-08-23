# G3 — History Snapshots

## Objective

Add the local History archive for generated outputs before connecting the real
Foundation Models pipeline.

## Tasks

- [ ] Define the History snapshot model and source-journal relationship.
- [ ] Store summary, reflection, digest, date, revision, and coverage metadata.
- [ ] Add a local History repository or data boundary.
- [ ] Connect the accepted History UI to mock-to-real local snapshots.
- [ ] Preserve older snapshots when a journal is edited.
- [ ] Delete private derived snapshots when the source journal is deleted.
- [ ] Verify History remains readable without a model call.
- [ ] Create a fresh reviewer after each task and after the goal.

## Acceptance criteria

- A History snapshot can be saved, listed, opened, and read after relaunch.
- Each snapshot has a clear date and source journal relationship.
- Summary, reflection, and digest are displayed distinctly.
- Privacy behavior for edit and delete is deterministic.
