# Decision 0002 — Insight Navigation and Lifecycle

## Decision

MaiJur keeps generated insight attached to its source journal instead of
providing a separate History tab.

- A current per-journal insight is reopened from Journal Detail.
- Editing a journal deletes the insight derived from the previous revision.
- Deleting a journal deletes its derived insight.
- If a removed per-journal insight was covered by Overall Insight, Overall
  Insight is invalidated and must be regenerated from the remaining current
  insights.
- Regeneration replaces the current insight for that journal; MaiJur does not
  expose old generated versions as a user-facing archive.

## Why

Generated text is derived private data, not the source of truth. Keeping a
stale reflection after the journal changes can misrepresent the author's latest
entry, while retaining multiple hidden versions adds storage and product
complexity without helping the current personal-project scope.

The source journal remains the durable record. Insight can be regenerated on
demand, and invalidating dependent Overall Insight prevents stale conclusions
from continuing to appear.

## Consequences

- Editing journal content intentionally removes the previous insight.
- The UI should show the generate state after an edit rather than an outdated
  result.
- Overall Insight may disappear after editing or deleting a covered journal and
  becomes available again when valid current insight exists.
- Preserving or browsing historical generated versions is out of scope.

## Related documents

- `docs/goals/G3-history-snapshot.md`
- `docs/specs/003-history.md`
- `docs/specs/004-foundation-models.md`
