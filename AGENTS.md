# MaiJur Agent Guide

## Project identity

MaiJur is a small, native iPhone journaling app. It helps a person create,
read, edit, and delete personal journal entries. Foundation Models may later
generate a summary, a personal reflection, and a rolling digest. The core app
must remain useful without an account, a server, or an internet connection.

The target test device is iPhone 17. The UI should feel native to Apple
platforms and should use Apple frameworks before introducing any dependency.

## Current phase

The repository is currently in the documentation and skeleton phase. The first
implementation goal is the UI using mock data. Do not implement persistence or
Foundation Models before the native UI goal is accepted.

The source of truth is organized as follows:

- `docs/goals/` — ordered goals and task checklists.
- `docs/specs/` — behavior and technical requirements for each goal.
- `docs/agents/` — role-specific instructions for the engineering loop.
- `docs/workflow/engineering-loop.md` — the required brainstorm → implement →
  fresh review cycle.
- `docs/decisions/` — decisions that should not be rediscovered repeatedly.

## Engineering principles

### Native Apple first

- Prefer SwiftUI, SwiftData, Foundation Models, Observation, OSLog, and other
  Apple frameworks already suited to the problem.
- Prefer system components and platform conventions over custom UI primitives.
- Do not add a third-party package unless the active spec explains why the
  native APIs are insufficient.

### KISS, YAGNI, DRY, SOLID, and separation of concerns

- Keep the smallest design that satisfies the active goal.
- Do not build future features, abstractions, settings, or infrastructure early.
- Extract shared behavior only when duplication is real and stable; avoid
  speculative generic helpers.
- Keep UI, persistence, Foundation Models orchestration, and formatting
  responsibilities separate.
- Use protocols at meaningful boundaries, not as decoration around every type.
- Prefer simple concrete Swift types when there is only one implementation.
- A view should not own database or model-session orchestration.

## Product constraints

- Journals and generated insights are local data by default.
- No account, authentication, server sync, or analytics is part of the initial
  product.
- Keep the number of screens small. The initial navigation can use two primary
  destinations: Journals and History, with push navigation or sheets for
  editor/detail states.
- The user must be able to journal even when Foundation Models are unavailable.
- Do not silently discard journal text when an AI request cannot fit the
  runtime context window.

## Foundation Models constraints

- Summary and reflection use separate `LanguageModelSession` instances so each
  task has a clear role and a smaller transcript.
- The current journal is sent once to the summary session. A reflection uses
  the new summary plus the latest rolling digest, not every raw historical
  journal.
- The digest is both an application-memory input for future requests and a
  user-visible snapshot stored in History.
- Use a simple `@Generable` schema. Keep property names and descriptions short
  because the schema contributes to the context window.
- Put trusted role and behavior in instructions. Put journal text and other
  user-controlled content in prompts.
- Include journal dates and coverage metadata in prompts and stored records;
  do not rely on the model alone to determine recency.
- Measure token usage at runtime. Initial budgets are hypotheses to validate on
  the target device, not permanent product guarantees.
- Keep the UI in a usable state when the model is unavailable, unsupported, or
  returns an error.

## Engineering loop

Every task or goal follows the workflow in `docs/workflow/engineering-loop.md`:

1. A brainstorming agent defines scope, acceptance criteria, and risks.
2. The implementer works only on the approved active task.
3. A new reviewer subagent is created with clean context for each completed
   task or goal.
4. The reviewer evaluates the spec, diff, tests, and acceptance criteria.
5. The task is complete only after review findings are resolved and verification
   evidence exists.

The reviewer must not inherit the brainstorming or implementation transcript.
The reviewer may request changes but does not silently modify the code.

## Change boundaries

- Read the active goal and spec before changing files.
- Do not start the next goal while the current goal is in review or blocked.
- Do not rewrite unrelated files or perform broad refactors.
- Preserve existing user changes.
- If a requirement conflicts with the active spec, stop and record the decision
  before implementing.
- Do not claim a build or test passed without running it and recording the
  relevant result.

## Verification

Once an Xcode project exists, discover the actual project, scheme, destination,
and available test targets before writing build commands. Do not invent a
scheme name. At minimum, verify the active goal with the smallest relevant
build, preview, unit test, or UI test available.

## Communication format

Agent updates should be short and concrete:

- active goal and task
- files changed
- verification performed and result
- remaining blocker or next review action

Avoid dumping the whole repository, repeating settled decisions, or explaining
general Swift concepts that are not relevant to the active change.
