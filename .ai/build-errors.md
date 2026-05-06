# Build errors / blockers

## 2026-05-06 — Step 0.1 verification skipped

`xcodebuild -scheme Kizba -destination 'platform=macOS' build` was **not** run.

Reason: `Kizba.xcodeproj` does not exist yet. Per user policy, the project must be
created via Xcode UI (manual). The agent does not have GUI access in this
environment, so it staged placeholder sources and detailed manual instructions
at `.ai/xcode_instructions.md` instead of synthesizing a `.xcodeproj` that
would diverge from Xcode's UI output.

**Action required from user:** follow `.ai/xcode_instructions.md`, then either
notify the agent or run the verification commands locally:

```sh
xcodebuild -scheme Kizba -destination 'platform=macOS' build
xcodebuild test  -scheme Kizba -destination 'platform=macOS'
```

After both succeed, increment `.ai/step.md` from `0` to `1` and continue with
step 0.2.
