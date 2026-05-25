# Changelog

## Unreleased — Kizba Night migration (Steps 1–5)

- Add new semantic color tokens and Day‑1 aliases: surfaceCard, surfaceCardHover, surfaceCardFlat, surfaceCardInteractive, accentSecondary, accentStrong, buttonPrimaryFill, buttonSecondaryFill, buttonDestructiveFill, buttonGhostPressedFill.
- Implement KizbaNightContrastTests (WCAG AAA/AA contracts and High-Contrast non-regression checks).
- Dark retune: dark surface changed to 0x111018; surfaceSunken adjusted to 0x0B0A12; mirrored into darkHighContrast as needed.
- Card variants: introduce elevated, flat, and interactive styles; wire hover composites and add CardVariantTests.
- Buttons: wire semantic button tokens and switch KizbaButtonStyle to resolve backgrounds via tokens; update tests and add ButtonVariantTests.

Verification: full test suite locally — PASS (1302 tests, 17 skipped, 0 failures).
