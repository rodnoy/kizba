# Files Retrieved

1. `Kizba/Presentation/DesignSystem/Theme/ColorTokens.swift` — Struct with 25 semantic color properties + memberwise init. Must add 4 new properties: `surfaceCard`, `surfaceCardHover`, `accentSecondary`, `accentStrong`.
2. `Kizba/Presentation/DesignSystem/Theme/Theme+Dark.swift` — `static let dark = ColorTokens(...)` with hex literals. Must add 4 new arguments aliased to existing values.
3. `Kizba/Presentation/DesignSystem/Theme/Theme+Light.swift` — `static let light = ColorTokens(...)`. Same addition needed.
4. `Kizba/Presentation/DesignSystem/Theme/Theme+HighContrast.swift` — Contains `lightHighContrast` and `darkHighContrast` statics. Same addition needed for both.

# Key Structures

- `ColorTokens`: `public struct`, `Sendable, Equatable`, memberwise `public init`.
- Theme variants are `static let` extensions on `ColorTokens` in separate files.
- Day-1 aliases per plan: `surfaceCard ≡ surfaceElevated`, `surfaceCardHover ≡ surfaceHover`, `accentSecondary ≡ focusRingOuter`, `accentStrong ≡ accent`.

# Architecture

```
ColorTokens (value type)
  ├─ Theme+Dark.swift       → .dark
  ├─ Theme+Light.swift      → .light
  └─ Theme+HighContrast.swift → .lightHighContrast, .darkHighContrast
```

All consumed via `theme.colors.<token>` in views. No call sites need updating (new tokens only).

# Recommended Starting Point

1. Add 4 properties to `ColorTokens` struct (after `surfaceSelected` for surface tokens, after `accentMuted` for accent tokens).
2. Extend `init` with 4 new parameters.
3. Add corresponding arguments in all 4 theme variant statics, aliased to existing sibling values.

# Risks / Unknowns

- Forgetting a variant → immediate compile error (safe).
- Ensure property ordering in init matches declaration order for readability.
- `Equatable` conformance is synthesized — adding properties is safe.
- No snapshot tests should break (no visual change).

# Recon

- **2025-05-23T00:00:00Z** | HEAD: `533fe1ec04e0ed28f9a38432427dab3047a5d30f` | Stack: Swift 5.10 / macOS 14 / SwiftUI | Task: Step 1 "Token foundation" — add 4 new `ColorTokens` properties with day-1 aliases across all theme variants. Additive, no visual change.
- **2026-05-23T21:42:13Z** | HEAD: `483fa8c0911fd72e043f6f7fe00ae155512a4d35` | Step 1 implementation completed locally; added additive token aliases in `ColorTokens` and all theme variants, no new hex values.
