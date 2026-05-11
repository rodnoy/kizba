# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B — COMPLETED.
Phase C — COMPLETED.
Phase D — COMPLETED.
Phase E — COMPLETED.

E.1 — COMPLETED (ShellInvocation + stdin pipe).
E.2 — COMPLETED (ProcessShellRunner stdin).
E.3 — COMPLETED (Opt-in E2E Pass+Git).
E.4 — COMPLETED (Docs & final regression sweep).

## MVP 4 release checklist

- [ ] Run full tests:
  `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
- [ ] Build Release:
  `xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build`
- [ ] Confirm grep bans:
  `rg -n '\bas!\b' Kizba`
  `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
- [ ] Optionally run opt-in Git E2E:
  `KIZBA_E2E=1 KIZBA_GIT_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassGitE2ETests`
- [ ] Tag release.
- [ ] Update release notes.

## Next action

MVP 4 complete. Next milestone: MVP 5 planning.
