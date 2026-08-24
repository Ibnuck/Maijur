# MaiJur Documentation

This folder is the working source of truth for MaiJur. The initial MVP feature
set through G4 is implemented; G5 quality validation is next. These documents
keep product decisions, specifications, and ordered goals separate from the
Swift source code.

## Structure

```text
docs/
├── agents/       Archived role instructions from the engineering-loop experiment
├── decisions/    Decisions that affect multiple goals
├── goals/        Ordered delivery goals and task checklists
├── research/     Notes and links from the Foundation Models research
├── specs/        Scope and acceptance criteria for each goal
└── workflow/     Archived engineering-loop reference
```

## How to use the documents

1. Select the first incomplete goal in `goals/roadmap.md`.
2. Read its matching goal file and spec.
3. Keep implementation limited to that goal's remaining acceptance criteria.
4. Verify the change with the smallest relevant build, test, or device check.
5. Update the goal and any affected decision when actual behavior changes.

The active goal is `G5 — Quality, Accessibility, and Performance`. G1–G4
describe the implemented MVP foundation and should not be reopened to add new
scope unless a defect requires it.

## Scope rule

These documents describe the initial MaiJur product. New ideas should be
recorded as a proposed decision or future goal instead of silently expanding an
active goal.
