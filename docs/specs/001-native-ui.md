# Spec 001 — Native UI Foundation

## Goal

Build the complete initial user interface with mock data so product flow and
visual hierarchy can be evaluated before persistence or Foundation Models are
connected.

## Navigation

Use a small native navigation structure:

- `Journals` — the primary list and entry creation flow.
- `History` — dated AI insight snapshots.

Use `NavigationStack` for detail and editor states. Avoid adding settings,
onboarding, accounts, or extra tabs in the first version.

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
- reserved presentation area for generated insights without calling the model;
- clear empty state when no insights exist.

### History

- dated list of mock insight snapshots;
- summary, reflection, and digest sections in a readable detail view;
- empty state when no History exists;
- visible relationship between an insight snapshot and its source journal date.

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
- real History persistence;
- authentication or sync;
- custom animations that do not support comprehension;
- settings and theming systems.

## Acceptance criteria

- A user can navigate between Journals and History.
- A user can preview the create, read, edit, and delete flows using mock data.
- Empty, populated, and loading-like presentation states are represented.
- The UI uses native Apple components and works with Dynamic Type.
- The UI can be reviewed without any network, account, database, or model call.
- The goal has previews or an equivalent repeatable way to inspect the main
  states.
