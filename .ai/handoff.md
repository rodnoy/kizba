# Kizba — Handoff

## Last completed action

Step **2.5 — DONE** (EntryDetailView + EntryDetailModel).

Implemented the detail (right) column of the root
`NavigationSplitView`. `EntryDetailModel` is an `@Observable
@MainActor` final view model whose `state` cycles through
`idle | loading | loaded(PassSecret) | failed(PassError)`. The
model reacts to `AppState.selectedEntryID` (forwarded by the view
through `.onChange(initial: true)`): it cancels any in-flight task,
bumps a generation counter so a late result cannot clobber the UI,
and schedules a new `passManager.show(_:)` invocation. `PassSecret`
lives only inside `state.loaded(_:)` for the duration of the current
selection — never on `AppState`, never persisted, never logged.

Copy actions are exposed as `copyPassword(clearAfterSeconds:)`,
`copyMetadata(forKey:clearAfterSeconds:)` and a generic
`copy(_:clearAfterSeconds:)`. All three forward verbatim values to
`ClipboardServicing.copy(_:clearAfter:)` with `Duration.seconds(N)`
(default 30s) — no key/value composition, per `.ai/decisions.md`.

`EntryDetailView` renders each phase: placeholder text for idle, a
`ProgressView` for loading, a `LoadedSecretView` (masked password
with Reveal/Hide toggle, per-field Copy buttons, optional notes
block) for `loaded`, and a `FailedView` with a sanitised summary and
a stubbed "View details" button (the real Diagnostics deep link
lands in Phase 8). `RootSplitView` now hosts the real
`EntryDetailView` in place of the previous `EmptyDetailView`
placeholder. Total test count: **80 passing** (76 from prior phases
+ 4 EntryDetailModel).

### Coverage added

- **`Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift`** —
  `@Observable @MainActor` final class. Owns `state` and
  `isPasswordRevealed`; private generation counter + `loadTask`
  enforce single-active-load semantics; copy helpers forward to
  `ClipboardServicing` with `Duration` clear-after.
- **`Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift`** —
  switch over `model.state`; `LoadedSecretView` with masked-password
  + Reveal/Hide + per-field Copy; `FailedView` mapping each
  `PassError` case to a one-line title and sanitised body; stubbed
  `View details` button.
- **`Kizba/Presentation/Root/RootSplitView.swift`** — detail column
  now uses `EntryDetailView(environment:state:)`; placeholder removed.
- **`KizbaTests/EntryDetailModelTests.swift`** — 4 tests:
  successful load → `.loaded(secret)`; rapid-selection churn against
  a 200 ms-delayed `SlowPassManager` keeps only the last selection's
  secret; clearing selection mid-flight returns to `.idle`; copy
  helpers record verbatim values + correct `Duration` on
  `RecordingClipboard`. File-local doubles (`SlowPassManager`,
  `RecordingClipboard`, `NoopClipboardForTests`,
  `InMemorySettingsStoreForTests`) so production wiring is untouched.

### Applied changes

- `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift` (new).
- `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift` (new).
- `Kizba/Presentation/Root/RootSplitView.swift` (use real view; drop placeholder).
- `KizbaTests/EntryDetailModelTests.swift` (new).
- `.ai/build-log.md` — appended step 2.5 verification block.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (file-system
  synchronized root group).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 80 tests, with 0 failures (0 unexpected) in 1.249 (1.377) seconds
```

Build log: `.ai/build-log.md`.

### Commits

- `7d81c1a` — `feat(ui): add EntryDetailModel and EntryDetailView`
- `5edadc8` — `test(ui): add EntryDetailModel tests`

### Repo state at completion

- HEAD: `5edadc8`.
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required this round — synchronized groups).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **Phase 2 — step 2.6** per `.ai/plan.md`
(`EntryDetailModelTests` selection-change cancellation + final-state
correctness — already partially covered here; step 2.6 may extend
fixtures or close the Phase 2 DoD with the verification matrix).

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Shell/`/`Pass/`).
- `PassSecret` not Codable, not CustomStringConvertible.
- `PassSecret` lives only in the active `EntryDetailModel`, never in
  `AppState`.
- `PassManaging` MVP-1 surface stays read-only — no write/git methods.
- `MockPassManager` and its fixtures stay behind `#if DEBUG` so the
  release binary ships without them (re-checked in Phase 9.1).
- `AppEnvironment.live()` placeholders fail deterministically — any
  production wiring gap surfaces immediately at first call.
- All chat with user in Russian; all code/comments/docs/commits in
  English.

## Machine-readable summary

See `.ai/last-run.json`.
