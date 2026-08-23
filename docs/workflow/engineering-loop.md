# MaiJur Engineering Loop

MaiJur uses a small three-role loop. The roles are separate to reduce scope
drift and review bias.

```text
Brainstormer
    ↓ approved design and acceptance criteria
Implementer
    ↓ changed files and verification evidence
Fresh Reviewer
    ├── APPROVED → mark task/goal complete
    ├── CHANGES_REQUESTED → return concrete findings to implementer
    └── BLOCKED → resolve external blocker before continuing
```

## Task state machine

```text
BACKLOG → READY → IN_PROGRESS → IN_REVIEW → VERIFIED → COMPLETE
                         ↑              │
                         └── CHANGES_REQUESTED
```

Only one task is `IN_PROGRESS` at a time unless a goal explicitly documents a
safe independent split. A goal cannot be marked complete while one of its
blocking tasks is open.

## Brainstorm phase

The brainstormer reads the active goal and spec, defines the smallest scope,
records non-goals, and writes acceptance criteria. It must stop for approval
before implementation if a decision changes architecture, product behavior,
privacy, or scope.

## Implementation phase

The implementer reads only the relevant context and works on one approved task.
It uses native Apple APIs, keeps changes focused, and runs the smallest useful
verification. It hands off a concise change summary and evidence.

## Fresh review phase

A new reviewer subagent is created after each completed task or goal. It receives
the spec, acceptance criteria, diff, and verification output, but not the prior
agent transcript. It checks behavior, scope, architecture, accessibility,
privacy, and verification. It returns one verdict and concrete findings.

## Completion rule

Mark a task or goal complete only when:

- every acceptance criterion is satisfied;
- the reviewer returns `APPROVED`;
- blocking findings are resolved;
- verification evidence is recorded;
- the roadmap and relevant checklist are updated.

If the reviewer requests changes, do not create a new goal. Return to the same
task, address the findings, and create another fresh reviewer.

## Token and context discipline

- Read the active goal and relevant files first; do not scan the entire repo.
- Keep agent handoffs concise and artifact-based.
- Do not repeat settled decisions in every prompt.
- Do not pass all historical journal text to a Foundation Models session.
