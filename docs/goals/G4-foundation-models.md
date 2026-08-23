# G4 — Foundation Models Generation

## Objective

Connect optional on-device Foundation Models generation to the accepted local
journaling and History flows.

## Tasks

- [ ] Check runtime model availability and device/language prerequisites.
- [ ] Define compact `@Generable` output types.
- [ ] Implement the summary session.
- [ ] Implement the reflection session using summary plus latest digest.
- [ ] Implement digest update using previous digest plus new summary.
- [ ] Add date and coverage metadata to prompts and stored outputs.
- [ ] Add runtime token/context measurement and a deliberate oversized-input
  strategy.
- [ ] Add model-unavailable, generation-failure, and incomplete-output states.
- [ ] Save only valid completed outputs as History snapshots.
- [ ] Confirm previously processed raw journals are not unnecessarily resent.
- [ ] Evaluate output quality in Indonesian on the target device.
- [ ] Create a fresh reviewer after each task and after the goal.

## Acceptance criteria

- Summary and reflection use separate sessions.
- Digest is rolling and does not require all raw historical journals.
- Generated output is stored locally and visible in History.
- A model failure never deletes or corrupts the source journal.
- Token usage and output quality are measured rather than guessed.
