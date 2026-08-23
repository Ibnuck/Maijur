# G1 — Native UI With Mock Data

## Objective

Finish the first usable visual flow of MaiJur before connecting persistence or
Foundation Models.

## Tasks

- [ ] Create the Xcode SwiftUI app shell and confirm the target configuration.
- [ ] Add the two primary destinations: Journals and History.
- [ ] Define a small mock journal data source for previews and UI inspection.
- [ ] Build the populated Journals list.
- [ ] Build the empty Journals state.
- [ ] Build the journal editor with date and text input.
- [ ] Build journal detail and mock edit/delete affordances.
- [ ] Build the populated History list and History detail state.
- [ ] Build empty and unavailable-insight states.
- [ ] Add loading-like presentation states needed by later persistence/AI flows.
- [ ] Add previews for the main states and Dynamic Type sizes.
- [ ] Check VoiceOver labels and obvious touch target issues.
- [ ] Run a fresh reviewer for each completed task and then for the goal.

## Explicit non-goals

- SwiftData or any real persistence;
- Foundation Models calls;
- accounts, sync, settings, search, tags, attachments, and notifications;
- custom design system or third-party UI package.

## Acceptance criteria

- The user can understand the app's purpose from the initial screen.
- The user can navigate Journals and History.
- Create, read, edit, and delete flows are represented with mock data.
- The UI remains usable in empty, populated, and unavailable-insight states.
- The visual design uses native Apple components and supports Dynamic Type.
- The UI can be reviewed without a network connection or a persistent store.
