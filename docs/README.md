# MaiJur Documentation

This folder is the working source of truth for MaiJur while the app is being
built. It keeps product decisions, agent roles, specifications, and ordered
goals separate from the Swift source code.

## Structure

```text
docs/
├── agents/       Role instructions for brainstorming, implementation, review
├── decisions/    Decisions that affect multiple goals
├── goals/        Ordered delivery goals and task checklists
├── research/     Notes and links from the Foundation Models research
├── specs/        Scope and acceptance criteria for each goal
└── workflow/     The engineering loop used for every task
```

## How to use the documents

1. Select the first incomplete goal in `goals/roadmap.md`.
2. Read its matching goal file and spec.
3. Run the brainstormer role to confirm scope and acceptance criteria.
4. Let the implementer work only on the approved task.
5. Create a fresh reviewer for the completed task or goal.
6. Mark the goal complete only when review findings and verification are done.

The initial implementation goal is `G1 — Native UI`. It must use mock data so
the UI can be evaluated before persistence and Foundation Models are added.

## Scope rule

These documents describe the initial MaiJur product. New ideas should be
recorded as a proposed decision or future goal instead of silently expanding an
active goal.
