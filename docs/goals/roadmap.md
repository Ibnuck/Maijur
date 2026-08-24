# MaiJur Goal Roadmap

The initial personal-project MVP goals G0–G5 are implemented and verified.

| ID | Goal | Priority | Status | Depends on |
|---|---|---:|---|---|
| G0 | Project foundation and agent workflow | P0 | Complete | — |
| G1 | Native UI foundation | P0 | Complete | G0 |
| G2 | Local journaling CRUD | P0 | Complete | G1 |
| G3 | Per-journal insight snapshots | P1 | Complete | G2 |
| G4 | Foundation Models generation | P1 | Complete | G3 |
| G5 | Quality, accessibility, and performance | P1 | Complete | G4 |

## Status definitions

- `Backlog` — defined but not started.
- `Next` — the next implementation goal after its dependency is complete.
- `In progress` — the current goal has active tasks.
- `In review` — implementation is done and is being checked against its
  acceptance criteria.
- `Complete` — acceptance criteria and proportionate verification are complete.
- `Blocked` — an external issue prevents progress and is recorded in the goal.

## Goal order

### G0 — Project foundation

Create the source-of-truth documents, agent roles, engineering loop, `.gitignore`,
and future source skeleton. See `G0-project-foundation.md` and
`specs/000-project-foundation.md`.

### G1 — Native UI

Build the small native Apple navigation and initial states, supported by mock
data for previews and deterministic UI inspection.
See `G1-native-ui.md` and `specs/001-native-ui.md`.

### G2 — Local journaling CRUD

Connect the UI to local persistence and implement create, read, edit, and
delete. See `G2-local-journaling.md` and `specs/002-local-journaling.md`.

### G3 — Per-journal insight snapshots

Add local insight storage and a dedicated Insight page reached from each
journal. No global History tab is required.
See `G3-history-snapshot.md` and `specs/003-history.md`.

### G4 — Foundation Models

Add separate structured-generation tasks for per-journal insight, incremental
Overall Insight, validation/repair, and failure handling.
See `G4-foundation-models.md` and `specs/004-foundation-models.md`.

### G5 — Quality

Validate accessibility, performance, error states, and target-device behavior.
See `G5-quality.md`.
