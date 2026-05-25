# Goal

Prepare and open a GitHub PR summarizing Kizba Night migration Steps 1–5 for reviewer consumption.

# Constraints

- Branch from current HEAD (post Step 5.7 sign-off).
- No code changes — PR is documentation/summary only (all code already committed on the working branch).
- Commit message and file contents in English.
- Use `gh` CLI for PR creation.

# Tasks

## Task 1 — Create PR branch and summary files
- Objective: Create branch, write PR body and changelog, commit, push, open PR.
- Files to modify: `.github/pull_request_body.md` (new), `CHANGELOG.md` (new or append)
- Verification: `gh pr view` shows the PR with correct title and body.
- Risks: If `gh` is not authenticated, push/PR creation will fail. Check with `gh auth status` first.

# Execution Plan (machine-friendly)

```
# Step 1: Verify prerequisites
gh auth status
git status  # ensure clean working tree

# Step 2: Create PR branch from current HEAD
git checkout -b feature/kizba-night-steps-1-5

# Step 3: Create PR body file
mkdir -p .github
cat > .github/pull_request_body.md << 'EOF'
## Kizba Night — Steps 1–5 Summary

### What this PR does

Implements the first five steps of the Kizba Night design-system migration:

1. **Step 1 — Token foundation**: Added `surfaceCard`, `surfaceCardHover`, `accentSecondary`, `accentStrong` to `ColorTokens` with Day-1 aliases across all theme variants.
2. **Step 2 — Contrast tests**: Added `KizbaNightContrastTests` (7 tests) locking WCAG contracts for body text (AAA), accent (AA), password-reveal (AAA), and HC non-regression.
3. **Step 3 — Dark retune**: Shifted dark `surface` to `0x111018` and `surfaceSunken` to `0x0B0A12`; mirrored in `darkHighContrast`. All contrast tests pass with improved ratios.
4. **Step 4 — Card variants**: Added `surfaceCardFlat`, `surfaceCardFlatHover`, `surfaceCardInteractive`, `surfaceCardInteractiveHover` tokens with Day-1 aliases. Added `CardVariantTests` (3 tests).
5. **Step 5 — Button variants**: Added `buttonPrimaryFill`, `buttonSecondaryFill`, `buttonDestructiveFill`, `buttonGhostPressedFill` tokens. Switched `KizbaButtonStyle` to semantic tokens (removed `theme.id` dispatch). Added `ButtonVariantTests` (4 tests).

### Key design decisions

- All new tokens use **Day-1 aliases** (point to existing values) — no visual change until future retune steps.
- `KizbaButtonStyle` no longer branches on `theme.id` for ghost pressed state — uses `buttonGhostPressedFill` semantic token.
- Dark surface deepened from `0x15121C` → `0x111018` (Night aesthetic); all WCAG contracts preserved or improved.

### Test coverage

- **1302 tests**, 17 skipped, **0 failures** (full suite verified at each step).
- New test files: `KizbaNightContrastTests`, `CardVariantTests`, `ButtonVariantTests`.

### Files changed (key)

- `Kizba/Presentation/DesignSystem/Theme/ColorTokens.swift`
- `Kizba/Presentation/DesignSystem/Theme/Theme+Dark.swift`
- `Kizba/Presentation/DesignSystem/Theme/Theme+Light.swift`
- `Kizba/Presentation/DesignSystem/Theme/Theme+HighContrast.swift`
- `Kizba/Presentation/DesignSystem/Components/KizbaButtonStyle.swift`
- `KizbaTests/KizbaNightContrastTests.swift`
- `KizbaTests/CardVariantTests.swift`
- `KizbaTests/ButtonVariantTests.swift`
- `KizbaTests/KizbaButtonStyleTests.swift`

### How to verify

```bash
xcodebuild test -scheme "Kizba" -destination 'platform=macOS'
```

All 1302 tests should pass with 0 failures.
EOF

# Step 4: Create/append CHANGELOG
cat > CHANGELOG.md << 'EOF'
# Changelog

## [Unreleased] — Kizba Night (Steps 1–5)

### Added
- `ColorTokens`: `surfaceCard`, `surfaceCardHover`, `accentSecondary`, `accentStrong` (Step 1)
- `ColorTokens`: `surfaceCardFlat`, `surfaceCardFlatHover`, `surfaceCardInteractive`, `surfaceCardInteractiveHover` (Step 4)
- `ColorTokens`: `buttonPrimaryFill`, `buttonSecondaryFill`, `buttonDestructiveFill`, `buttonGhostPressedFill` (Step 5)
- `KizbaNightContrastTests` — WCAG contrast regression tests (7 tests)
- `CardVariantTests` — card token alias + contrast tests (3 tests)
- `ButtonVariantTests` — button token alias + contrast tests (4 tests)

### Changed
- Dark theme `surface` deepened: `0x15121C` → `0x111018` (Step 3)
- Dark theme `surfaceSunken` deepened: `0x0F0D16` → `0x0B0A12` (Step 3)
- Dark HC `accentMuted` opacity: `0.34` → `0.28` (Step 2.4 contrast fix)
- `KizbaButtonStyle.backgroundColor` now resolves via semantic button tokens instead of `theme.id` dispatch (Step 5)
EOF

# Step 5: Commit
git add .github/pull_request_body.md CHANGELOG.md
git commit -m "docs: Add PR summary and changelog for Kizba Night Steps 1-5"

# Step 6: Pre-push verification
xcodebuild test -scheme "Kizba" -destination 'platform=macOS' 2>&1 | tail -5
# Expect: "Test Suite 'All tests' passed" with 0 failures

# Step 7: Push and open PR
git push -u origin feature/kizba-night-steps-1-5
gh pr create \
  --title "Kizba Night: Steps 1–5 (Token foundation, Contrast tests, Dark retune, Card variants, Button variants)" \
  --body-file .github/pull_request_body.md \
  --base main
```

# Suggested current step

Task 1 — execute the shell commands above sequentially. Abort if `gh auth status` fails or if `xcodebuild test` reports failures.
