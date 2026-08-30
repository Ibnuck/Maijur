# Spec 004 — Foundation Models Integration

## Goal

Add optional on-device generation for per-journal insights and an incremental
Overall Insight while preserving local-first journaling.

## Session design

Use separate sessions with one clear responsibility each:

1. **Summary task** receives the current journal and its date. Long legacy input
   can be summarized in chunks and merged by a separate synthesis session.
2. **Reflection task** receives the current summary and date. It addresses the
   author only as `you`/`your`; a correction session repairs first-person output.
3. **Theme task** receives the current summary and returns short noun phrases,
   not another reflection or narrative summary.
4. **Overall Insight update** receives the previous Overall Insight plus at most
   three new dated per-journal insight snapshots. It never receives all raw
   historical journals.

Each task uses a fresh `LanguageModelSession` so transcripts do not accumulate
across unrelated responsibilities.

## Output direction

The output should be useful for self-understanding rather than artificially
short:

- summary: a neutral, concise account preserving events, thoughts, stated
  emotions, and outcomes;
- reflection: normally two to four short paragraphs plus two or three optional
  reflective questions, written directly to the author;
- themes: two to five short noun phrases;
- Overall Insight: distinct overview, recurring patterns supported by multiple
  dated insights, and a recent focus based on the newest supplied insight.

Initial target ranges are hypotheses to validate on the target device, not
visible product limits. `maximumResponseTokens` is a safety ceiling; it must
not be set so low that valid output is routinely truncated.

## Input and context strategy

- The editor enforces a visible limit of 2,400 characters for new and edited
  journals. This is a product input limit, not an exact token guarantee.
- If an entry is too large, preserve the original locally and use a deliberate
  paragraph- and sentence-aware chunking strategy. Never silently cut stored
  journal text.
- Keep instructions, prompts, `@Generable` schema, and requested output within
  the session context budget.
- Use dates as explicit metadata so newer summaries can be prioritized without
  asking the model to infer chronology from prose alone.

## Structured generation

Use a small `@Generable` output type with only fields that the UI needs. Keep
property names and descriptions short. Avoid deeply nested types unless testing
shows they improve the result enough to justify context cost.

Journal text is user-controlled prompt content. Trusted behavior and safety
constraints belong in instructions, not inside untrusted journal text.

## Availability and failure behavior

- Journals and previously saved insights remain usable when the model is
  unavailable, unsupported, busy, or unable to complete a request.
- Save only completed, valid structured output as an insight snapshot.
- Keep the source journal even if generation fails.
- Present a recoverable error without exposing or copying private journal text
  into the error message.
- English is the internal processing language. Non-English journal input is
  translated to English before generation, and every completed per-journal or
  Overall Insight output is translated to Indonesian before its user-visible
  fields are saved.
- If the Indonesian translation is unavailable or incomplete, save no partial
  insight. Keep the source journal and any previously valid insight unchanged.
- Require every field to be nonempty, then validate the complete internal
  payload as English and the complete user-visible payload as Indonesian before
  persistence. Substantive prose fields are also checked independently; short
  theme phrases are checked with their payload because isolated phrase
  detection is unreliable.
- Stored English processing fields may be reused by incremental Overall Insight,
  but user-visible insight fields must have `displayLanguageCode == "id"`.

## Out of scope

- server-side model fallback;
- custom model training or adapters;
- automatic background analysis of every journal;
- sending journal content to third-party services.

## Acceptance criteria

- Summary, reflection, themes, and Overall Insight are generated through the
  defined task boundaries.
- A successful run creates the corresponding per-journal insight snapshot.
- A failed run never deletes or corrupts the source journal.
- Previously processed raw journals and covered per-journal insight IDs are not
  repeatedly included in Overall Insight updates.
- Runtime context, token usage, latency, and output quality are explicit G5
  validation items.
