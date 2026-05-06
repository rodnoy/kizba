# Kizba — Build Log

## 2026-05-06 — Step 0.1 verification

Host: macOS, Xcode 26.4.1 (Build 17E202).
Project: `Kizba.xcodeproj` (committed, HEAD `2f4b549`).
Scheme: `Kizba` (auto-generated, NOT shared — see notes).
Targets: `Kizba` (app), `KizbaTests` (XCTest).

### Build

Command:
```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
```

Result: **BUILD SUCCEEDED**.

### Test

Command:
```
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

Result: **TEST SUCCEEDED**.

Suite `KizbaTests`:
- `testExample()` — passed (0.001 s)
- `testPerformanceExample()` — passed (0.801 s)

### Notes / deviations from plan (non-blocking for step 0.1 DoD)

The current Xcode project deviates from `.ai/decisions.md` in several settings.
These are recorded here for follow-up but are out of scope for step 0.1, which only
requires that `xcodebuild build` and `xcodebuild test` pass:

- `MACOSX_DEPLOYMENT_TARGET = 26.4` — decisions.md mandates `14.0`.
- `SWIFT_STRICT_CONCURRENCY` — not explicitly set in pbxproj (Xcode 26 default may
  already imply strict concurrency, but should be made explicit per decisions.md).
- `SWIFT_TREAT_WARNINGS_AS_ERRORS` — not set on Kizba target.
- Scheme `Kizba` is not shared (no `Kizba.xcodeproj/xcshareddata/xcschemes/`).
  Required for reproducible CI; user should share via Xcode → Product → Scheme →
  Manage Schemes → check "Shared".
- `KizbaUITests` target — not present (good; matches plan: target was never
  created, so deletion step is a no-op).
- App source layout: `Kizba/KizbaApp.swift` exists at top level of `Kizba/`
  rather than under `Kizba/App/` as planned. The `Kizba/App/KizbaApp.swift`
  staged in commit `eaefd6b` is not part of the Xcode target. Folder
  scaffolding (step 0.3) will need to either move sources or update Xcode
  group references.

These items will be addressed in subsequent steps (0.2, 0.3, and a settings
alignment pass) per the plan.
