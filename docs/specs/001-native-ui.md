# Spec 001 — Native UI Foundation

## Goal

Build the complete initial user interface with mock data so product flow and
visual hierarchy can be evaluated before persistence or Foundation Models are
connected.

## Navigation

Use a small native navigation structure:

- `Journals` — the primary list and entry creation flow.
- `Insight` — a dedicated page reached from one journal's detail.

Use `NavigationStack` for detail and editor states. Avoid adding settings,
onboarding, accounts, or tabs in the first version.

## Required UI states

### Journals

- list of mock journal entries sorted by date;
- empty state for a new user;
- toolbar action to create a journal;
- clear date and readable preview text;
- edit and delete affordances consistent with native list behavior.

### Journal editor

- date display or date selection;
- focused `TextEditor` for journal content;
- save and cancel actions;
- unsaved-content behavior defined before persistence is connected;
- no visible AI warning or token configuration in the initial UI.

### Journal detail

- full journal text;
- date and edit action;
- a clear action that opens the journal's separate Insight page.

### Insight

- dedicated presentation away from the journal input and reading surface;
- story essence, reflection space, and developing-pattern sections;
- clear empty, generating, result, and unavailable states;
- results remain associated with their source journal and are reopened through
  that journal's detail.

## Design direction

- Use system colors, typography, spacing, navigation, list rows, toolbar items,
  sheets, and materials where appropriate.
- Keep the visual language calm and personal without introducing a custom design
  system prematurely.
- Support Dynamic Type and VoiceOver-friendly labels.
- Use previews and deterministic mock data for all major states.

## Out of scope

- SwiftData integration;
- Foundation Models calls;
- real insight persistence;
- authentication or sync;
- custom animations that do not support comprehension;
- settings and theming systems.

## Acceptance criteria

- A user can navigate from a journal to its dedicated Insight page.
- A user can preview the create, read, edit, and delete flows using mock data.
- Empty, populated, and loading-like presentation states are represented.
- The UI uses native Apple components and works with Dynamic Type.
- The UI can be reviewed without any network, account, database, or model call.
- The goal has previews or an equivalent repeatable way to inspect the main
  states.
