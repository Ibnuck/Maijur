# G5 — Quality, Accessibility, and Performance

**Status:** Next

## Objective

Make the initial MaiJur experience reliable and comfortable on the target
device after the core feature goals are complete.

## Tasks

- [ ] Test Dynamic Type and VoiceOver across the main flows.
- [ ] Validate touch targets, contrast, focus, and keyboard behavior.
- [ ] Measure launch, list scrolling, persistence, and model-generation latency.
- [ ] Use Instruments only where measurements show a real question.
- [ ] Verify memory behavior with longer journal and insight collections.
- [ ] Verify model context and output behavior on the target device.
- [ ] Remove unnecessary abstractions and duplicate formatting discovered during
  review.
- [ ] Run all automated tests and record the final target-device verification.

## Acceptance criteria

- Core journaling works without AI.
- Main flows are usable with accessibility settings enabled.
- No known data-loss path remains in the initial scope.
- Performance issues are measured and either fixed or explicitly recorded.
