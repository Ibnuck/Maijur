# Decision 0003 - Indonesian Insight Display

## Decision

Every successfully saved and displayed generated insight must be in Indonesian,
regardless of the journal's source language.

- English is the internal processing language for per-journal and Overall
  Insight generation.
- Non-English journal text is translated to English before generation.
- Completed generated output is always translated from English to Indonesian
  before its user-visible fields are saved.
- English processing fields remain stored for incremental Overall Insight
  updates without repeated translation.
- If language detection, translation, generation, or output validation fails,
  MaiJur saves no partial insight and keeps the source journal unchanged.
- Every translated input and generated processing field must be nonempty; the
  complete processing payload and each substantive prose field must be detected
  as English before it can continue or be persisted.
- Every translated user-visible field must be nonempty; the complete display
  payload and each substantive prose field must be detected as Indonesian
  before persistence. Short theme phrases are validated with their complete
  payload because language detection is unreliable for isolated phrases.
- Existing snapshots whose display language is not Indonesian are treated as
  incompatible and can be regenerated.

## Why

MaiJur's interface and intended reading experience are Indonesian. A fixed
display language avoids mixed-language insight cards and makes Overall Insight
updates consistent, while retaining English processing fields keeps Foundation
Models prompts bounded and stable.

## Consequences

- English journals still require output translation before an insight can be
  saved.
- Indonesian and other non-English journals use a source -> English ->
  Indonesian pipeline.
- Translation availability is now required for a successful insight run, but
  never for the core journaling flow.
- Prompt versions are bumped so older derived results do not bypass the new
  language contract.

## Related documents

- `docs/specs/004-foundation-models.md`
- `docs/goals/G4-foundation-models.md`
- `docs/decisions/0002-insight-lifecycle.md`
