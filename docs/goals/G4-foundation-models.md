# G4 — Foundation Models Generation

**Status:** Complete for the current MVP scope

## Objective

Connect optional on-device Foundation Models generation to per-journal Insight
and incremental Overall Insight flows.

## Tasks

- [x] Check runtime model availability before generation.
- [x] Define compact `@Generable` output types.
- [x] Implement separate summary, reflection, and theme tasks.
- [x] Implement incremental Overall Insight from the previous result plus at
  most three new per-journal insights per session.
- [x] Add journal dates and coverage IDs to prompts and stored outputs.
- [x] Enforce a visible 2,400-character journal limit and retain a
  paragraph-aware chunking path for oversized legacy input.
- [x] Add model-unavailable, generation-failure, invalid-perspective, and
  malformed-output handling.
- [x] Save only completed structured outputs as local insight snapshots.
- [x] Avoid resending raw historical journals and previously covered insight
  IDs during Overall Insight updates.
- [x] Validate the current English-output strategy on the target iPhone 17.

Runtime token-usage instrumentation and broader language evaluation are G5
validation work. They are not required to call the current MVP generation flow
implemented.

## Acceptance criteria

- Summary and reflection use separate sessions.
- Theme extraction is separate from summary and reflection.
- Overall Insight is incremental and does not require raw historical journals.
- Generated output is stored locally and visible from its journal or the
  Overall Insight entry point.
- A model failure never deletes or corrupts the source journal.
- Model availability and output quality are verified on the target device;
  quantitative token and performance measurement continues in G5.
