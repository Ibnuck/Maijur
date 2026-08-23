# G2 — Local Journaling CRUD

## Objective

Connect the accepted UI to local device storage and deliver the initial CRUD
feature set.

## Tasks

- [ ] Define the local journal model and revision metadata.
- [ ] Configure the SwiftData model container.
- [ ] Add a focused local repository or data boundary.
- [ ] Replace mock list data with persisted reads.
- [ ] Implement create and save.
- [ ] Implement edit while preserving journal identity.
- [ ] Implement intentional delete confirmation.
- [ ] Handle store-open and save failures without losing the source text.
- [ ] Verify persistence across relaunch.
- [ ] Create a fresh reviewer after each task and after the goal.

## Acceptance criteria

- Journal CRUD works locally and survives relaunch.
- No account or server is required.
- The UI remains usable when persistence is unavailable.
- Content revision metadata is available for future AI processing.
