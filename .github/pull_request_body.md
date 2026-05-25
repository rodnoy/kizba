Kizba Night migration — Steps 1–5

Summary

- Token foundation: added new semantic color tokens (surfaceCard, surfaceCardHover, accentSecondary, accentStrong) and Day‑1 aliases across all theme variants.
- Contrast tests: implemented automated WCAG-based contrast checks (KizbaNightContrastTests) and HC non-regression assertions to lock visual contracts.
- Dark retune: shifted dark surface to Night (`0x111018`) and adjusted surfaceSunken; mirrored changes into high-contrast variants where required.
- Card variants: introduced surfaceCard aliases and card-style variants (elevated, flat, interactive) with unit tests.
- Buttons: added dedicated button tokens and switched KizbaButtonStyle to resolve backgrounds via semantic tokens; updated tests and added ButtonVariantTests.

Verification

- Local CI: full test suite passed locally: 1302 tests, 17 skipped, 0 failures.
- Targeted tests executed during development: KizbaButtonStyleTests, ButtonVariantTests, KizbaNightContrastTests — all passing.
- Contrast math uses the project's ContrastChecker and composites translucent tokens with alphaCompositedOver when appropriate.

Files / Areas to review

- Design system tokens: Kizba/Presentation/DesignSystem/Theme/ColorTokens.swift and Theme+*.swift
- Token usage: Kizba/Presentation/DesignSystem/Components/KizbaButtonStyle.swift
- Tests: KizbaTests/KizbaNightContrastTests.swift, KizbaTests/KizbaButtonStyleTests.swift, KizbaTests/ButtonVariantTests.swift, KizbaTests/CardVariantTests.swift

Notes for reviewers

- Day‑1 changes are aliases only (no visual diffs) except where the plan explicitly retuned dark palette colors.
- No Color hex literals were introduced outside DesignSystem theme files (SourceGrepTests enforce this).
- Focus review on token naming, token wiring in theme variants, and the contrast test semantics.

How to run locally

- Run the full suite:
  xcodebuild test -scheme "Kizba" -destination 'platform=macOS'
