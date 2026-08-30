# G4 — Foundation Models Generation

**Status:** In review - Indonesian output device validation pending

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
- [x] Make English the internal processing language and Indonesian the required
  display language for every newly generated insight.
- [ ] Validate English, Indonesian, and one additional journal language on the
  target iPhone 17, including the missing-language-pack failure path.

Runtime token-usage instrumentation remains a G5 validation item. The fixed
Indonesian display contract requires a focused target-device check because the
Translation framework session cannot be fully exercised by unit tests.

## Acceptance criteria

- Summary and reflection use separate sessions.
- Theme extraction is separate from summary and reflection.
- Overall Insight is incremental and does not require raw historical journals.
- Generated output is stored locally and visible from its journal or the
  Overall Insight entry point.
- Every successfully stored user-visible insight field is Indonesian; English
  is retained only in internal processing fields.
- A model failure never deletes or corrupts the source journal.
- Model availability and output quality are verified on the target device;
  quantitative token and performance measurement continues in G5.
