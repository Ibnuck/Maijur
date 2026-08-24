# Spec 004 — Foundation Models Integration

## Goal

Add optional on-device generation for a journal summary, personal reflection,
and rolling digest while preserving local-first journaling and the per-journal
insight snapshot contract.

## Session design

Use separate sessions with one clear responsibility each:

1. **Summary session** receives the current journal and returns structured
   summary data.
2. **Reflection session** receives the current summary, the latest digest, and
   date metadata; it does not receive all historical raw journals.
3. **Digest update session** receives the previous digest and the new summary to
   produce the next compact digest.

The application stores the resulting digest locally. It is not treated as
permanent model-session memory.

## Output direction

The output should be useful for self-understanding rather than artificially
short:

- summary: concise but complete, normally two or three short paragraphs plus
  a small set of observed themes;
- reflection: normally two to four short paragraphs plus two or three optional
  reflective questions;
- digest: a compact, cumulative description of recurring themes, preferences,
  emotional patterns, and recent context grounded in the available journals.

Initial target ranges are hypotheses to validate on the target device, not
visible product limits. `maximumResponseTokens` is a safety ceiling; it must
not be set so low that valid output is routinely truncated.

## Input and context strategy

- Start testing with roughly 2,000–2,500 characters for one journal as an
  internal budget hypothesis, then tune from measured runtime token usage and
  output quality.
- Do not show a warning merely because the journal reaches this initial
  hypothesis.
- Check token usage and context capacity at runtime.
- If an entry is too large, preserve the original locally and use a deliberate
  paragraph-aware condensation or chunking strategy. Never silently cut text.
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
- Log diagnostics locally without logging full private journal text by default.
- Validate Indonesian output quality and device language/model availability on
  the actual target configuration; do not assume language support from the UI
  locale alone.

## Out of scope

- server-side model fallback;
- custom model training or adapters;
- automatic background analysis of every journal;
- sending journal content to third-party services.

## Acceptance criteria

- Summary, reflection, and digest are generated through the defined session
  boundaries.
- A successful run creates the corresponding per-journal insight snapshot.
- A failed run never deletes or corrupts the source journal.
- Previously processed raw journals are not repeatedly included in the next
  request when the rolling digest is sufficient.
- Runtime context and output usage can be inspected during testing.
