# Kizba — Handoff

## Last completed action

Step **0.3 — DONE** (folder scaffolding + KizbaApp move).

Created the target architecture skeleton under `Kizba/` (App, Domain,
Infrastructure, Presentation, Resources subtrees) with `.keep` placeholder
files in every otherwise-empty group. Moved the app entry point into
`Kizba/App/KizbaApp.swift` and relocated `Assets.xcassets` into
`Kizba/Resources/`.

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+),
so file additions/moves under `Kizba/` are picked up automatically. The
only `project.pbxproj` change was a single
`PBXFileSystemSynchronizedBuildFileExceptionSet` excluding the twelve
`.keep` placeholders from the `Kizba` target's bundle resources (without
exceptions, all `.keep` files would be copied to the same
`Resources/.keep` output path and the build would fail with "Multiple
commands produce ...").

### Applied changes

- `Kizba/{App, Domain/Models, Domain/Protocols, Infrastructure/{Shell,
  Pass, Store, Clipboard, Discovery, Settings, Logging},
  Presentation/{Root, Features, DesignSystem}, Resources}/` created.
- 12 × `.keep` placeholders in the empty groups.
- `Kizba/KizbaApp.swift` → `Kizba/App/KizbaApp.swift` (content unchanged).
- `Kizba/Assets.xcassets/` → `Kizba/Resources/Assets.xcassets/`.
- `Kizba.xcodeproj/project.pbxproj`: added one
  `PBXFileSystemSynchronizedBuildFileExceptionSet`
  (`E9411DE02FAB8D6900ED03E6`) wired into the `Kizba`
  `PBXFileSystemSynchronizedRootGroup` `exceptions` list.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
# => ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    KizbaTests.testExample            passed
#    KizbaTests.testPerformanceExample passed
```

Build log: `.ai/build-log.md`.

### Commits

- `65d84d6` — `feat(scaffold): add project folder skeleton with .keep files`
- `f4a7ac0` — `refactor(app): move KizbaApp.swift into App group`

### Repo state at completion

- HEAD: `f4a7ac0` (will advance after this handoff/log commit).
- Xcode project: `Kizba.xcodeproj/` committed, `Kizba` scheme shared.
- App sources: `Kizba/App/KizbaApp.swift`,
  `Kizba/Resources/Assets.xcassets/`.
- Tests: `KizbaTests/KizbaTests.swift` (2 tests).
- `xcodeproj_created = true`, `xcode_instructions_path = .ai/xcode_instructions.md`.

## Next action

Proceed to **step 1.1** (Phase 1 — Domain types):
- Create value types in `Kizba/Domain/Models/`: `PassEntry.swift`,
  `PassMetadata.swift`, `PassSecret.swift`, `PassError.swift`.
- `PassSecret` must be `Sendable`, NOT `Codable`, NOT
  `CustomStringConvertible`, NOT `CustomDebugStringConvertible`.
- Replace the corresponding `.keep` in `Domain/Models/` (delete it once
  the directory has real files).

After 1.1: 1.2 (protocols in `Domain/Protocols/`) → 1.3 (domain unit tests).

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Shell/`/`Pass/`).
- `PassSecret` not Codable, not CustomStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.

## Machine-readable summary

See `.ai/last-run.json`.
