# macOS Sequoia (15.x) Smoke Test Notes

This document captures macOS Sequoia (15.x) compatibility notes and a manual smoke test checklist for Kizba. macOS 15 introduced changes around `Process` spawn permissions (TCC) and clipboard access that warrant verification.

## Background — what changed in Sequoia

- **Clipboard reads**: Sequoia introduced per-paste user prompts when an app reads the pasteboard from a different app. **Kizba writes its own clipboard content** (via `ClipboardService` from MVP1) and reads `changeCount` to verify it wasn't overwritten — neither pattern triggers the new prompt. Auto-clear (per `clipboardClearDelaySeconds` setting; default 30s; wired in MVP2 Phase A.6) is a pure write→snapshot→write cycle, also unaffected.
- **`Process` spawn**: Sequoia tightened sandboxing for sandboxed apps. **Kizba is not sandboxed** (per `.ai/decisions.md`: Developer ID + notarization, outside the App Store; sandboxing deferred to MVP3). The `Process` spawn calls to `/opt/homebrew/bin/pass`, `/opt/homebrew/bin/gpg`, etc. should work without TCC prompts on a non-sandboxed Developer ID app.
- **Hardened Runtime + library validation**: Notarization requires Hardened Runtime. The entitlement `com.apple.security.cs.disable-library-validation = true` in `Kizba.entitlements` (MVP1 Phase A.8 era) is required so spawned `gpg`/`pinentry-mac` can load their own libraries.

## Smoke test checklist

Run these manually on a Sequoia 15.x Mac with `pass` (≥ 1.7.3) + `gpg` + `pinentry-mac` installed and a populated `~/.password-store`.

### Cold-launch behavior
- [ ] App launches without Gatekeeper warnings (signed Developer ID build).
- [ ] No TCC prompts on first launch (pasteboard, file system, Process spawn).
- [ ] Sidebar populates with folders from `~/.password-store`.

### Read flow (MVP1)
- [ ] Selecting an entry triggers `pass show` → `pinentry-mac` prompts for passphrase → entry decrypts and renders.
- [ ] Subsequent `show` calls within the gpg-agent cache window do NOT re-prompt.
- [ ] Copy password (⌘C) → paste in another app within `clipboardClearDelaySeconds` → succeeds.
- [ ] Wait > delay → paste → buffer cleared (clipboard empty or replaced by another app's content).

### Write flow (MVP2)
- [ ] ⌘N → fill form → Save → success toast → new entry appears in list, selected.
- [ ] ⌘E → modify → Save → success toast → entry updated; verify NO second pinentry prompt within the agent cache window.
- [ ] ⌘⌥G (detail toolbar 🎲) → Regenerate → success toast → password rotated (verify by ⌘C + paste).
- [ ] ⌘⇧M → new path → Move → success toast → entry at new path; selection follows the moved entry.
- [ ] ⌫ → Delete → confirm dialog → success toast → entry gone; click **Undo** within 10s → entry restored at original path.

### Concurrent-write lockout
- [ ] Trigger a slow write (e.g., when pinentry is up but unresolved). Verify all OTHER write toolbar buttons + write menu items are disabled while the in-flight save runs. Read-side actions (Refresh, Settings, Diagnostics) stay enabled.

### Diagnostics
- [ ] ⌘⌥D → Diagnostics window opens with sanitized invocation log.
- [ ] Failed `pass show` (e.g., wrong passphrase 3x) appears in log with sanitized stderr; secret content NOT visible; emails / long hex IDs replaced by `<redacted-email>` / `<redacted-id>`.

### Known issues (none expected)

If any prompt or unexpected behavior appears, document it here:

- (none observed yet — fill in as smoke testing happens)

## How to run

```sh
# Build a signed local Release
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# For day-to-day smoke testing, a local Debug build is sufficient:
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
open ~/Library/Developer/Xcode/DerivedData/Kizba-*/Build/Products/Debug/Kizba.app
```

Codesign + notarize per `RELEASE.md` (when written; tracked in MVP2 Phase I.6).

## Verification status

Fill in dates + verifier as you run the checklist.

| Item | Verified on date | Verifier |
|---|---|---|
| Clipboard auto-clear | — | — |
| Process spawn (no TCC prompt) | — | — |
| Pinentry flow | — | — |
| Hardened Runtime + library validation | — | — |
| All 5 write ops (create/edit/regenerate/move/delete) | — | — |
| Concurrent-write lockout | — | — |
| Diagnostics window | — | — |
| Undo (delete + move + in-place regenerate) within 10s | — | — |

## `pass` version fixture coverage (Phase I.5 verification)

Verified 2026-05-09 — both `pass` 1.7.3 AND 1.7.4 stderr / stdout shapes are represented in unit-test fixtures. No new fixtures were needed; this section is a record of where each version's quirks land.

### `KizbaTests/PassErrorMapperTests.swift` (E.4)

| Stderr signature | 1.7.3 | 1.7.4 | Test method |
|---|:-:|:-:|---|
| `Cowardly refusing to overwrite '<abs>.gpg'` (insert collision) | ✓ | ✓ | `testEntryAlreadyExists_cowardlyRefusing` (comment: "pass 1.7.3 / 1.7.4 emits this") |
| `Error: <path> already exists.` (generate collision) | ✓ | ✓ | `testEntryAlreadyExists_alreadyExistsBareForm` (comment: "pass 1.7.3 emits this from `pass generate`"; 1.7.4 unchanged) |
| `mv: refusing to overwrite '<abs>.gpg'` (mv(1) underlying `pass mv`) | ✓ | ✓ | `testEntryAlreadyExists_mvRefusingToOverwrite` (mv(1) is shell-level, version-invariant) |
| `gpg: <id>: skipped: No public key` | ✓ | ✓ | `testRecipientNotFound_email`, `testRecipientNotFound_hexKeyId` (gpg(1) message, version-invariant across `pass`) |
| `Error: pass-length [...] must be a positive integer.` | ✓ | ✓ | `testInvalidLength_quotedToken`, `testInvalidLength_bareForm` |
| `Error: password store is empty. Try "pass init".` | ✓ | ✓ | `testInvalidGpgId_passwordStoreEmpty` |
| `You must run "pass init" first.` | ✓ | ✓ | `testInvalidGpgId_youMustRunPassInit` |
| `Error: <path> is not in the password store.` (context-dependent) | ✓ | ✓ | `testIsNotInPasswordStore_*` (4 variants) |

Conclusion: every write-side stderr shape from BOTH 1.7.3 and 1.7.4 is exercised. The bare `Error: <path> already exists.` form is the only signature that differs textually between `pass insert` (cowardly form) and `pass generate` (already-exists form); both are covered.

### `KizbaTests/PassGenerateParserTests.swift` (D.5)

| Stdout shape | 1.7.3 | 1.7.4 | Test method |
|---|:-:|:-:|---|
| Plain text (no TTY) | ✓ |   | `testParsePass173PlainOutput` |
| Colored (ESC[4m path / ESC[1mESC[33m password / ESC[0m), TTY-attached | ✓ |   | `testParsePass173ColoredOutput` |
| Plain text (no TTY) |   | ✓ | `testParsePass174PlainOutput` |
| Colored, TTY-attached |   | ✓ | `testParsePass174ColoredOutput` |
| `--in-place` plain | ✓ | ✓ | `testParseInPlacePlainOutput` (shape identical to non-in-place; covered for both) |
| `--in-place` colored | ✓ | ✓ | `testParseInPlaceColoredOutput` |
| Defensive: trailing-newline / ANSI-only / git-style noise / bare single line | n/a | n/a | `testParseTolerantTo*`, `testParseDefensiveAgainstGitStyleStdoutNoise`, etc. |

Conclusion: both versions explicitly named in test methods. The `--in-place` variant emits stdout identical in shape to plain `pass generate` (the difference is purely side-effectual: rewrites the existing entry rather than creating a new one), so the version split there is implicit but covered by the stdout-shape coverage.

### Outcome

Both `pass` versions (1.7.3 minimum supported per MVP2 baseline; 1.7.4 the current Homebrew default) are explicitly represented in the fixture corpus. **No fixture additions were needed in I.5.**
