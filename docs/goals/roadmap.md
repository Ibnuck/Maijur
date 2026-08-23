# MaiJur Goal Roadmap

Goals are completed in order. The first implementation goal is UI, using mock
data. Do not start a later goal while the active goal has unresolved review
findings.

| ID | Goal | Priority | Status | Depends on |
|---|---|---:|---|---|
| G0 | Project foundation and agent workflow | P0 | Complete | — |
| G1 | Native UI with mock data | P0 | Next | G0 |
| G2 | Local journaling CRUD | P0 | Backlog | G1 |
| G3 | History snapshots | P1 | Backlog | G2 |
| G4 | Foundation Models generation | P1 | Backlog | G3 |
| G5 | Quality, accessibility, and performance | P1 | Backlog | G4 |

## Status definitions

- `Backlog` — defined but not started.
- `Next` — the next implementation goal after its dependency is complete.
- `In progress` — the current goal has active tasks.
- `In review` — implementation is done and a fresh reviewer is evaluating it.
- `Complete` — acceptance criteria, review, and verification are complete.
- `Blocked` — an external issue prevents progress and is recorded in the goal.

## Goal order

### G0 — Project foundation

Create the source-of-truth documents, agent roles, engineering loop, `.gitignore`,
and future source skeleton. See `G0-project-foundation.md` and
`specs/000-project-foundation.md`.

### G1 — Native UI

Build the small native Apple navigation and all initial states with mock data.
See `G1-native-ui.md` and `specs/001-native-ui.md`.

### G2 — Local journaling CRUD

Connect the UI to local persistence and implement create, read, edit, and
delete. See `G2-local-journaling.md` and `specs/002-local-journaling.md`.

### G3 — History snapshots

Add the local model and UI for dated summary, reflection, and digest snapshots.
See `G3-history-snapshot.md` and `specs/003-history.md`.

### G4 — Foundation Models

Add separate sessions, structured output, rolling digest, and failure handling.
See `G4-foundation-models.md` and `specs/004-foundation-models.md`.

### G5 — Quality

Validate accessibility, performance, error states, and target-device behavior.
See `G5-quality.md`.
