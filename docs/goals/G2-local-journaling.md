# G2 — Local Journaling CRUD

**Status:** Complete

## Objective

Connect the accepted UI to local device storage and deliver the initial CRUD
feature set.

## Tasks

- [x] Define the local journal model, revision, and content-hash metadata.
- [x] Configure the SwiftData model container.
- [x] Keep persistence orchestration behind `JournalStore` rather than views.
- [x] Load persisted journals into the Journals flow.
- [x] Implement create and save.
- [x] Implement edit while preserving journal identity.
- [x] Implement intentional delete confirmation.
- [x] Handle store-open and save failures with visible recoverable errors.
- [x] Verify persistence by reopening the same model container in tests and on
  the target device.

## Acceptance criteria

- Journal CRUD works locally and survives relaunch.
- No account or server is required.
- The UI remains usable when persistence is unavailable.
- Content revision metadata is available for future AI processing.
