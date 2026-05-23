# Handoff — Execute Step 1: Token foundation

## Task
**Step 1: Token foundation (additive, no visual change)**

## Assigned to
smart-worker

## Scope (files to change)
1. `Kizba/Presentation/DesignSystem/Theme/ColorTokens.swift`
2. `Kizba/Presentation/DesignSystem/Theme/Theme+Dark.swift`
3. `Kizba/Presentation/DesignSystem/Theme/Theme+Light.swift`
4. `Kizba/Presentation/DesignSystem/Theme/Theme+HighContrast.swift`

## What to do
1. Add 4 new `public let` properties to `ColorTokens`:
   - `surfaceCard: Color` (group with surfaces, after `surfaceSelected`)
   - `surfaceCardHover: Color` (after `surfaceCard`)
   - `accentSecondary: Color` (group with accents, after `accentMuted`)
   - `accentStrong: Color` (after `accentSecondary`)
2. Add corresponding parameters to the memberwise `public init` and assign them.
3. In each theme variant static (`dark`, `light`, `lightHighContrast`, `darkHighContrast`), add the 4 new arguments with day-1 aliases:
   - `surfaceCard: <same value as surfaceElevated in that variant>`
   - `surfaceCardHover: <same value as surfaceHover in that variant>`
   - `accentSecondary: <same value as focusRingOuter in that variant>`
   - `accentStrong: <same value as accent in that variant>`

## Verification
```bash
xcodebuild test -scheme "Kizba" -destination 'platform=macOS'
```
All existing tests must pass. No visual change.

## Acceptance criteria
- `ColorTokens` has 4 new properties.
- All 4 theme variants compile and supply the new tokens.
- Test suite is fully green.
- No new hex values introduced (aliases only).
- No existing call sites modified.

## Constraints
- No `Color.*` literals outside DesignSystem (SourceGrepTests enforces).
- Hex literals only in Theme+Dark/Light/HighContrast files.
- Light theme visually unchanged.
