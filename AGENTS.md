# MaiJur Agent Guide

## Project identity

MaiJur is a small, native iPhone journaling app. It helps a person create,
read, edit, and delete personal journal entries. Foundation Models optionally
generate per-journal insights and an incremental overall insight. The core app
remains useful without an account, a server, or an internet connection.

The target test device is iPhone 17. The UI should feel native to Apple
platforms and should use Apple frameworks before introducing any dependency.

## Current phase

The initial MVP implementation through G4 is complete: native UI, local CRUD,
per-journal insight persistence, and Foundation Models generation are present.
G5 quality, accessibility, and performance validation is the next goal. Avoid
adding new product features until that validation is complete.

The source of truth is organized as follows:

- `docs/goals/` — ordered goals and task checklists.
- `docs/specs/` — behavior and technical requirements for each goal.
- `docs/agents/` and `docs/workflow/` — archived references for the earlier
  engineering-loop experiment; they are not mandatory for current work.
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
- Keep the number of screens small. Journals is the single root destination;
  journal detail, per-journal Insight, and Overall Insight are reached from it.
- There is no global History tab. A saved per-journal insight is reopened from
  its source journal.
- The user must be able to journal even when Foundation Models are unavailable.
- Do not silently discard journal text when an AI request cannot fit the
  runtime context window.

## Foundation Models constraints

- Summary, reflection, and theme extraction use separate
  `LanguageModelSession` instances so each task has a clear role and a smaller
  transcript.
- The current journal is sent to the summary task. Reflection and themes use
  that summary plus date metadata; they do not receive raw historical journals.
- Overall Insight is updated from its previous stored result and at most three
  new dated per-journal insights per session. Previously covered insight IDs
  are not sent again.
- Editing a journal deletes its outdated derived insight. If Overall Insight
  covered that result, it is invalidated so stale conclusions are not shown.
- Use a simple `@Generable` schema. Keep property names and descriptions short
  because the schema contributes to the context window.
- Put trusted role and behavior in instructions. Put journal text and other
  user-controlled content in prompts.
- Include journal dates and coverage metadata in prompts and stored records;
  do not rely on the model alone to determine recency.
- The editor currently enforces a 2,400-character product limit. Keep runtime
  context and output measurement as a G5 validation task rather than assuming
  the character limit is an exact token guarantee.
- Keep the UI in a usable state when the model is unavailable, unsupported, or
  returns an error.

## Working approach

Use a direct implementation and verification workflow appropriate for this
small project. The earlier multi-agent engineering loop remains documented for
reference but is not required. Keep changes scoped, verify them proportionally,
and do not claim a build or test passed without evidence.

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
