# G0 — Project Foundation

## Objective

Create a small, explicit working foundation for the agent loop and future
MaiJur source code.

## Tasks

- [x] Create the root `.gitignore` for macOS, Xcode, Swift, generated output,
  and local secrets.
- [x] Create `AGENTS.md` with product constraints and engineering principles.
- [x] Create role instructions for brainstormer, implementer, and fresh
  reviewer.
- [x] Create the engineering loop document and task state machine.
- [x] Create the ordered roadmap and goal files.
- [x] Create the technical specs for UI, persistence, History, and AI.
- [x] Create the future source folder skeleton without feature code.
- [x] Review this foundation with a fresh reviewer.
- [x] Record review findings and resolve any blocking documentation issues.

## Review record

- Verdict: `APPROVED`
- Findings: none
- Reviewer provenance: a newly spawned, clean-context reviewer subagent with
  no brainstorming or implementation transcript
- Review scope: static inspection of the documentation, skeleton, and
  `.gitignore`
- Verification evidence: `find . -maxdepth 4 -print`, `rg --files`, targeted
  inspection of `AGENTS.md`, `.gitignore`, `docs/goals/roadmap.md`, and
  `docs/workflow/engineering-loop.md`; no `.swift` or Xcode project files were
  present

## Definition of done

- The project rules are discoverable from the repository root.
- A new agent can identify the active goal, its spec, and its review process.
- G1 is clearly the first implementation goal.
- No application feature code was introduced prematurely.
