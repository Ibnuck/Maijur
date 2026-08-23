# Decision 0001 — Native Apple Stack

## Decision

MaiJur will use SwiftUI and Apple-native frameworks as the default stack. The
initial architecture remains intentionally small:

- SwiftUI for presentation and navigation;
- SwiftData for local journal and History persistence;
- Foundation Models for optional on-device summary, reflection, and digest;
- Swift concurrency for asynchronous work;
- native Apple accessibility and system UI conventions.

## Why

MaiJur is a small personal iPhone app with local data and a limited initial
feature set. Native frameworks reduce dependency and maintenance cost, fit the
target platform, and support the desired Apple-native experience.

## Consequences

- The UI can be built and reviewed before persistence or AI exists.
- No server architecture is required for the initial product.
- Foundation Models availability and language support must be validated on the
  actual target configuration.
- Any third-party dependency requires a new decision explaining its value.

## Related documents

- `docs/specs/000-project-foundation.md`
- `docs/specs/001-native-ui.md`
- `docs/workflow/engineering-loop.md`
