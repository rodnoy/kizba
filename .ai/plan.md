# MVP6 — Phase E: Help Setup Topics

## Status of prior phases

- Phase A (Recents settings + fold): DONE
- Phase B (Settings tabs + Save feedback + InfoTooltip): DONE
- Phase C (App-wide tooltips + advisory grep rule): DONE
- Phase G (Critical UX fixes — Favorites toggle, sidebar tap routing, storage key namespace): DONE
- Phase D (Biometric availability gating + confirm-to-disable): DONE
- Test suite: 1056 tests, 0 failures. Release build clean.

## Goal

Extend the built-in Help app with three guided setup topics so users can bootstrap their environment from inside Kizba without leaving for external docs:
1. Install and configure pass-store + GPG.
2. Setup git remote (multi-device sync).
3. Configure pinentry-mac (macOS pinentry frontend).

Optionally surface these topics as Help menu deep-links (E.2) if `openWindow(id:value:)` plumbing is already in place; otherwise topics are still reachable via the Help app's sidebar.

No behavioural changes elsewhere. No new third-party deps.

## Constraints

- Swift 5.10, macOS 14, strict concurrency complete.
- No `as!`, no third-party deps, no stdin/stdout logging.
- DS-only styling.
- English-only UI strings.
- SourceGrepTests must stay green.
- **Append topics to `HelpCatalog.all` — NEVER insert in the middle.** Block IDs are positional; existing tests assume stability.

## Tasks

### E.1 — Three new setup topics in HelpCatalog

**Description:** Append three new `HelpTopic` definitions to `HelpCatalog.all` and provide first-class static accessors (mirror existing `aeadMDCCompatibility`).

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Help/HelpCatalog.swift`:
  - Add three new topic accessors (`setupPassAndGPG`, `setupGitRemote`, `configurePinentry`).
  - Append them to `HelpCatalog.all` in this order at the END.

**Topic 1 — `setupPassAndGPG`** ("Install pass-store and GPG"):
Sections (~5):
1. **Install via Homebrew** — `.commandSequence(["brew install pass gnupg"])` + paragraph.
2. **Generate a GPG key** — `.command("gpg --full-generate-key")` + paragraph + warning about passphrase.
3. **Initialize the store** — `.command("pass init <your-gpg-id>")` + paragraph + helper command.
4. **Verify it works** — `.commandSequence(["pass insert test/example", "pass test/example"])` + paragraph.
5. **Troubleshooting** — `.warning` + paragraph with external doc links.

**Topic 2 — `setupGitRemote`** ("Sync your store via Git"):
Sections (~5):
1. **Initialize git in your store** — `.command("pass git init")` + paragraph.
2. **Add a remote** — `.command("pass git remote add origin <your-repo-url>")` + paragraph.
3. **First push** — `.command("pass git push -u origin main")` + warning about main vs master.
4. **Sync between devices** — `.commandSequence` + paragraph.
5. **Conflicts** — `.warning` + paragraph.

**Topic 3 — `configurePinentry`** ("Configure pinentry-mac"):
Sections (~5):
1. **Install pinentry-mac** — `.command("brew install pinentry-mac")` + paragraph.
2. **Find the binary path** — `.command("which pinentry-mac")` + paragraph + warning about arch divergence.
3. **Configure gpg-agent** — `.commandSequence` + paragraph + warning.
4. **Restart the agent** — `.command("gpgconf --kill gpg-agent")` + paragraph.
5. **Smoke test** — `.command` + paragraph.

**API additions:**
```swift
public extension HelpCatalog {
    static var setupPassAndGPG: HelpTopic { /* ... */ }
    static var setupGitRemote: HelpTopic { /* ... */ }
    static var configurePinentry: HelpTopic { /* ... */ }
}
```
И добавить в `all` в конец массива.

**Tests:**
- `KizbaTests/HelpCatalogTests.swift` (extend existing):
  - `testCatalog_containsSetupPassAndGPGTopic`.
  - `testCatalog_containsSetupGitRemoteTopic`.
  - `testCatalog_containsConfigurePinentryTopic`.
  - `testSetupTopics_haveAccessors`.
  - `testSetupTopics_haveExpectedSectionCount`.
  - `testSetupTopics_containCommandAndWarningBlocks`.
  - Existing positional ID tests untouched.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/HelpCatalogTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `main` (direct landing per project workflow)
**Commit:** `feat(help): setup topics for pass/gpg, git remote, pinentry (MVP6.E.1)`
**Difficulty:** S
**Risks:**
- Positional ID test fragility — append-only, never insert.
- Apple Silicon vs Intel pinentry path divergence — warning block explicit.

---

### E.2 — Help menu deep-links (OPTIONAL — SKIPPED)

**Status: SKIPPED — plumbing not in place.**

Inspection of `Kizba/App/KizbaApp.swift` shows the Help scene is declared as `Window("Help", id: "help")` without a `for:` value-type, and `HelpModel.init` does not accept an `initialTopicID` parameter. Adding deep-link plumbing requires:
1. Switching the scene to `WindowGroup`-style `for: String.self` (or equivalent) wiring.
2. Threading the optional `initialTopicID` into `HelpModel`.
3. Reconciling with the existing assertion in tests that `helpWindowID == "help"`.

That ret rofit is larger than the Phase E budget allows and changes the window lifecycle (singleton vs identified). Topics remain reachable via the Help app's sidebar; deep-links are deferred to a future MVP.

---

## Acceptance criteria

### E.1
- [ ] `HelpCatalog.all` contains exactly +3 topics appended at the end.
- [ ] Each new topic has 4–6 sections with a mix of `.command`, `.commandSequence`, `.paragraph`, `.warning` blocks.
- [ ] First-class accessors `setupPassAndGPG`, `setupGitRemote`, `configurePinentry` exist.
- [ ] All new tests pass.
- [ ] Existing positional ID tests untouched and still green.

### E.2
- Skipped — documented as deferred above.

### Suite-wide
- [ ] Full Debug suite ≥1056 + new tests, 0 failures.
- [ ] Release build clean.
- [ ] Grep bans clean.

## Verification commands (Phase E final)

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
rg -n 'setupPassAndGPG|setupGitRemote|configurePinentry' Kizba/
```

## Suggested current step

Run **smart-worker** on **Task E.1** (three new Help topics).
