# Kizba — Accessibility Audit (MVP 3 Phase F.1)

This document captures the accessibility surface of Kizba as of MVP 2,
and defines a manual checklist the developer should run before each
release. Code-side guarantees are static (verified by reading source);
behavioural guarantees require manual verification against macOS
VoiceOver, Increase Contrast, Dynamic Type, and Reduce Motion settings.

## Code-side guarantees (verified in source)

### Theme & contrast
- Four canonical `Theme` constants (`.light`, `.dark`, `.lightHighContrast`,
  `.darkHighContrast`) shipped as code constants and selected at runtime
  by `ThemedRoot` (`Kizba/Presentation/DesignSystem/Theme/ThemedRoot.swift`)
  based on `colorScheme` × `colorSchemeContrast`. Every top-level `Scene`
  in `KizbaApp.swift` (main `WindowGroup`, `Settings`, `Window("Diagnostics")`)
  is wrapped in its own `ThemedRoot` so theme injection survives scene
  boundaries.
- All measured WCAG contrast contracts are locked by `ThemeTokenTests`
  using `ContrastChecker`: body text AA / AAA on every variant; password
  reveal AAA on every variant; focus-ring outer ≥ 3:1 vs surface and
  inner ≥ 3:1 vs both outer AND accent (see `decisions.md` 2026-05-09);
  banner severity icons ≥ 3:1 (SC 1.4.11) on every variant; banner body
  text ≥ 4.5:1 (SC 1.4.3) on every variant.
- Increase Contrast variants do not regress numerically against their
  standard counterparts for body text and password reveal (asserted in
  `ThemeTokenTests`); focus-ring tokens satisfy the three ring assertions
  independently per variant.

### Reduce Motion
- The motion contract is `MotionTokens.animation(_:reduceMotion:)`
  (`Kizba/Presentation/DesignSystem/Theme/MotionTokens.swift`); when
  `reduceMotion == true`, the helper returns `nil`, suppressing the
  animation at the call site.
- All five animation call sites in `Presentation/**` route through this
  helper; verified by repository-wide `rg '\.animation\('` (5 hits, all
  consume `theme.motion.animation(...)`):
  - `ToastOverlay.swift:53` — toast appearance/dismissal.
  - `LoadingShimmer.swift:50` — shimmer phase loop.
  - `KizbaButtonStyle.swift:176` — button press scale.
  - `KizbaFocusRing.swift:70` — focus ring fade.
- `LoadingShimmer.swift` (lines 30–46) additionally drops the gradient
  overlay entirely under reduce motion — only the static sunken
  rectangle remains, so users see a placeholder shape with no animated
  motion at all.
- `ToastOverlay.transition(reduceMotion:)` (line 62) returns `.identity`
  when reduce motion is on; the toast then appears/disappears without
  slide or fade.

### Focus
- Focus is rendered by a single shared modifier
  `KizbaFocusRing` (`Kizba/Presentation/DesignSystem/Components/KizbaFocusRing.swift`).
  Two-tone (outer + inner) by design; consumed by `KizbaButtonStyle` (line
  183) and any future focusable atom. Direct reads of
  `focusRingOuter` / `focusRingInner` outside this file are banned by
  Phase C.6 grep tests, guaranteeing one source of truth.
- `KizbaButtonStyle.ButtonContent` declares `@FocusState private var isFocused`
  and applies `.focusable(isEnabled)` so disabled buttons drop out of
  the keyboard tab chain.

### Color-blind safety (semantic state)
- `BannerView.iconName(for:)` (`BannerView.swift:87`) maps each severity
  to a fixed SF Symbol with a distinct silhouette so meaning never
  relies on colour alone:
  - `.info` → `info.circle.fill` (circle).
  - `.success` → `checkmark.circle.fill` (circle + check).
  - `.warning` → `exclamationmark.triangle.fill` (triangle).
  - `.danger` → `xmark.octagon.fill` (octagon).
- `ToastView` reuses `BannerView.iconName(for:)` (`ToastView.swift:33`)
  so the two surfaces carry the same icon-per-severity contract.
- `EntryRowView` selection state is communicated by both
  `surfaceSelected` background AND `accessibilityAddTraits(.isSelected)`
  (line 81), so a colour-blind user with VoiceOver still hears the
  selected state.

### Selection state announcement
- `EntryRowView` declares `.accessibilityElement(children: .combine)`
  and `.accessibilityAddTraits(isSelected ? .isSelected : [])`
  (`EntryRowView.swift:80–81`) so VoiceOver announces the row as a
  single combined element with the "Selected" trait when active.
  Subtitle (the entry path) is folded into the same combined
  announcement.
- `EmptyStateView` uses `.accessibilityElement(children: .combine)`
  (line 59) so the icon, title and message read as one node rather
  than three.
- `ToastView` and `ToastOverlay` both apply
  `.accessibilityElement(children: .combine)` +
  `.accessibilityAddTraits(.isStaticText)` so the toast reads as a
  single non-interactive utterance.

### Toast announcements
- `ToastOverlay.swift:43–50` posts an
  `AccessibilityNotification.Announcement(...)` on every new toast
  appearance, driven off the toast's `id` so it re-fires when one
  toast replaces another. Label text is composed via
  `ToastView.accessibilityLabel(for:title:message:)` which includes
  a severity prefix (`Info / Success / Warning / Error`), giving
  VoiceOver users the same severity cue sighted users get from the
  icon.

### Secret protection
- `SecretRevealField.swift:49` masks the value-bearing `Text` from
  VoiceOver:
  - When revealed: `accessibilityLabel(value)` reads the password.
  - When masked: `accessibilityLabel("Hidden secret")` — VoiceOver
    NEVER reads bullets, dots, or asterisks. The mask string
    (`String(repeating: "•", count: maskedLength(for: value))`) is
    pure visual chrome and is replaced by the explicit label.
- The reveal/hide toggle button has its own
  `accessibilityLabel(isRevealed ? "Hide secret" : "Reveal secret")`
  (line 57); state is communicated by relabelling rather than by a
  trait toggle (system trait support for "expanded/collapsed" is
  uneven on macOS).
- The detail view (`EntryDetailView.swift`) reads the password
  exclusively through `SecretRevealField`; no parallel `Text(secret.password)`
  exists. Metadata values use `Text(field.value)` directly with
  `.textSelection(.enabled)` — VoiceOver will read them, which is
  intentional (metadata is non-secret in the `pass` data model).
- Toast messages NEVER carry secret material — only entry path /
  status text. Documented as a code-review checkpoint in
  `decisions.md` (2026-05-08 § Security).

### Decorative iconography
- All purely decorative icons (icon-only, no semantic meaning beyond
  reinforcing adjacent text) are flagged
  `.accessibilityHidden(true)`:
  - `BannerView.swift:57` (severity icon — meaning is in the label).
  - `ToastView.swift:35` (severity icon — meaning is in the label).
  - `EntryRowView.swift:41, 63` (leading + accessory icons).
  - `EmptyStateView.swift:36` (large illustration icon).
  - `LoadingShimmer.swift:47` (entire shimmer is hidden — it's a
    placeholder, not content).
  - `FormFieldRow.swift:39` (leading label is hidden because the
    control inside the row carries the same label via line 43).

### Form labels
- `FormFieldRow` (`FormFieldRow.swift:43`) explicitly applies
  `.accessibilityLabel(label)` to its enclosed control, so even
  when the visual leading-label `Text` is hidden from VoiceOver the
  control inside the row is announced with the same label.
- `KeyValueEditor.swift:70` — remove-row button is `accessibilityLabel("Remove field")`.
- `FolderPathPicker.swift:48` — folder-suggestions menu trigger is
  `accessibilityLabel("Suggested folders")`.
- `SettingsView.swift:224` — file-picker ellipsis button is
  `accessibilityLabel("Browse")`.
- `GeneratePasswordSheet.swift:115` — regenerate-preview button is
  `accessibilityLabel("Regenerate password preview")`.
- `FormSection.swift:28` — section title carries
  `.accessibilityAddTraits(.isHeader)` so VoiceOver's "next heading"
  rotor jumps between sections.
- Toolbar buttons use SwiftUI's `Label("Action", systemImage: "icon")`
  pattern (e.g. `EntryListView.swift:67`, `EntryDetailView.swift:84,99`,
  `KizbaApp.swift:118+`). SwiftUI synthesises `accessibilityLabel`
  from the visible label text. Each toolbar button additionally
  carries a `.help(...)` tooltip that contains the keyboard
  shortcut.

### Dynamic Type
- Typography tokens (`TypographyTokens.swift`) are all built from
  `Font.system(_:)` style constants (`.largeTitle`, `.title`, `.headline`,
  `.body`, `.callout`, `.caption`) plus `.weight(_:)` adornments.
  No `.system(size: …)` literals exist anywhere in `Kizba/` — verified
  by `rg '\.system\(size:' Kizba` (0 hits). Dynamic Type therefore
  scales every text element in the app.

### Sidebar role announcement (I.3 fix)
- `SidebarView.swift:44` adds an explicit
  `.accessibilityLabel("\(folder.name), folder")` on each folder row
  so VoiceOver announces the row's semantic role. The leading
  `folder` SF Symbol is `accessibilityHidden(true)` inside
  `EntryRowView`, so without this override VoiceOver would read
  only the folder name with no role context.

## Manual verification checklist

Before each release, run through this checklist on a Mac with the
relevant accessibility features enabled.

### VoiceOver (System Settings → Accessibility → VoiceOver, ⌘F5)

- [ ] App launches; first Tab lands on a meaningful element; Tab order
      through Sidebar → EntryList → EntryDetail is logical.
- [ ] Each folder row in the Sidebar is announced as
      `<folder name>, folder` (carried by the explicit label added in
      `SidebarView.swift:44`) — not as bare `<folder name>`.
- [ ] Each entry row in the middle column is announced as one combined
      element: `<name>, <path subtitle>, selected` (when selected) —
      not as two separate fields.
- [ ] Toolbar buttons are announced by their full `Label` text
      ("New Entry", "Move Entry", "Delete Entry", "Refresh", "Edit
      Entry", "Regenerate Password"). Verify keyboard shortcut is
      surfaced (system reads `.help(...)` content under VoiceOver,
      typically at the end of the announcement).
- [ ] `SecretRevealField` (entry detail password row): when masked,
      VoiceOver says "Hidden secret" — NOT "bullet bullet bullet".
      When revealed, VoiceOver reads the actual password.
- [ ] Reveal/Hide toggle: announced as "Reveal secret" or "Hide secret"
      depending on state.
- [ ] Toast `.success` / `.warning` / `.danger` triggers an
      `AccessibilityNotification.Announcement` — VoiceOver reads it
      without the user needing to navigate. The announcement text is
      prefixed with the severity word ("Success — Entry created — …").
- [ ] Confirmation dialogs (Delete, Reset to Defaults) are announced
      with the system "destructive" trait on the confirm button.
- [ ] `FormSection` titles ("PATH", "PASSWORD", etc.) appear in the
      VoiceOver headings rotor (Ctrl+Option+U → Headings).

### Increase Contrast (System Settings → Accessibility → Display → Increase Contrast)

- [ ] Toggling the system setting swaps the in-app theme: dividers
      become visibly heavier, accent hue deepens, focus ring outer
      band reads as a more saturated azure.
- [ ] Body text contrast visibly deeper (muted-text role collapses
      onto the full-contrast `onSurface` colour in HC variants).
- [ ] Password reveal (`SecretRevealField`) stays AAA legible — both
      revealed and masked. The bullet mask should not become hard to
      see (it intentionally lightens in HC variants).
- [ ] Banners (`.success` / `.warning` / `.danger`) retain readability;
      icon and body text both visible against muted backgrounds.
- [ ] Light HC and Dark HC are both visually distinct from their
      standard counterparts (run the four variants in sequence as a
      sanity check).

### Dynamic Type (System Settings → Accessibility → Display → Text Size)

- [ ] Bumping system text size scales body, captions, headings, and
      monospace cells proportionally throughout the app.
- [ ] No clipping at "Larger" settings. Long entry paths in the middle
      column truncate with `…` (line-limited 1, `truncationMode(.tail)`
      for title, `.middle` for subtitle).
- [ ] `EntryRowView` title + subtitle stack vertically without the
      row growing past sensible bounds.
- [ ] Settings form fields scale; inputs remain typable at largest size.
      The fixed-width 140pt label column in `FormFieldRow` does NOT
      scale; verify long labels at large text sizes still render
      (today they truncate inside that 140pt column).
- [ ] Stepper / Toggle controls in `GeneratePasswordSheet` scale with
      text and remain operable.

### Reduce Motion (System Settings → Accessibility → Display → Reduce Motion)

- [ ] Toast appearance/dismissal becomes instant — no slide-in from
      the bottom edge, no fade.
- [ ] `LoadingShimmer` becomes a static rectangle — no moving
      gradient sheen.
- [ ] Focus ring transitions become instant — no fade-in / fade-out.
- [ ] Button press scale becomes instant (no smooth scale-down /
      scale-up).
- [ ] No spinning, sliding or flashing animations remain.

### Color filters (System Settings → Accessibility → Display → Color Filters)

- [ ] With Deuteranopia or Protanopia filter on, severity icons remain
      distinguishable purely by shape: info circle vs success
      checkmark-circle vs warning triangle vs danger octagon.
- [ ] Selection vs hover are still distinguishable in the entry list
      (selection uses a stronger surface tint; hover uses a fainter
      one — confirm both still read against the surface).
- [ ] Tritanopia filter: pastel surface tones may collapse — confirm
      the focus ring (sky-blue outer + neutral inner) is still
      visible against `surface`.

### Keyboard-only operation

- [ ] Every action is reachable via keyboard. The full shortcut audit
      (Phase I.1) covers: ⌘N (New), ⌘E (Edit), ⌘⌥G (Regenerate),
      ⌘⇧M (Move), ⌫ (Delete), ⌘R (Refresh), ⌘⌥D (Diagnostics), ⌘,
      (Settings via `SettingsLink`).
- [ ] Tab order traverses all interactive elements in each sheet
      (NewEntry, EditEntry, GeneratePassword, Move, Settings,
      Diagnostics).
- [ ] Esc dismisses every sheet and confirmation dialog (verify each
      sheet wires `.cancelAction` on Cancel — confirmed for
      `NewEntrySheet`, `GeneratePasswordSheet`; visually confirm
      others).
- [ ] Enter triggers the default action (Save / Use this password) in
      forms.
- [ ] Arrow keys navigate `List` selection in Sidebar and EntryList.

### Read-only operation against missing pass / gpg

- [ ] Without `pass` installed, app shows the `.emptyState` from
      `ErrorPresentation` with a `SettingsLink` action; VoiceOver
      announces both title and message via the combined-element
      `EmptyStateView`.
- [ ] Settings opens via `SettingsLink` (⌘,) and is fully
      keyboard-operable.

## Known gaps (severity tagged)

### High — should fix before MVP 3
- **None identified.** All identified high-impact gaps from the audit
  were either already covered (toast announcement, secret masking,
  selection trait) or addressed by the trivial fix in this phase
  (sidebar folder role announcement).

### Medium — should consider for MVP 3
- [x] **`SecretRevealField` toggle state not exposed via trait.** The
  reveal/hide button relabels itself ("Reveal secret" ↔ "Hide secret")
  but did not expose `.accessibilityValue`. This was addressed by
  adding an accessibilityValue helper and modifier (SecretRevealField.accessibilityValueText).
  (D.1)
- [x] **`KeyValueEditor` rows not combined into single VoiceOver elements.**
  Each row contained two `TextField`s plus a remove `Button`; VoiceOver
  navigated them as three separate stops. Per-row grouping + helper were
  added to KeyValueEditor to combine rows into single accessibility elements.
  (D.2)
- [x] **Editable cleartext password TextField in `NewEntrySheet` /
  `EditEntrySheet`.** The shared `EntryFormBody` now renders the
  password input as a `SecureField` by default and exposes a
  reveal/hide toggle that mirrors the read-only `SecretRevealField`
  vocabulary (`Hidden` / `Revealed`). The toggle defaults to masked
  so VoiceOver no longer reads characters aloud as the user types.
  (Phase D.3 closure)
- [x] **`FormFieldRow` 140pt fixed label column does not scale with
  Dynamic Type.** At "Larger Accessibility Size 5", long field labels
  truncate inside the column rather than wrapping or growing. A vertical
  layout for accessibility Dynamic Type sizes was added (FormFieldRow.shouldUseVerticalLayout).
  (D.3)
- [x] **Toolbar button announcements may not include keyboard shortcut.**
  The `.help(...)` tooltip contains the shortcut text ("New Entry
  (⌘N)") and SwiftUI on macOS is supposed to fold this into the
  VoiceOver utterance, but behaviour varies by VoiceOver verbosity
  setting. We added explicit `.accessibilityHint("Keyboard shortcut: …")`
  to the write toolbar buttons so the shortcut is announced reliably.
  (D.5)

### Low — backlog
- **No `.accessibilityValue` on the password Stepper in
  `GeneratePasswordSheet`.** The numeric label is rendered by a
  sibling `Text("\(model.length)")`; VoiceOver reads the stepper's
  default value (system-provided). Adding `.accessibilityValue("\(model.length) characters")`
  would be one line. — REMAINS OPEN (MVP 4 candidate)
- **`Toggle` and `Stepper` in Settings + GeneratePasswordSheet rely on
  system labels.** No explicit `.accessibilityLabel`. Acceptable
  because the visible `Text` is read; documented for completeness.
  — REMAINS OPEN (MVP 4 candidate)
- **`LoadingShimmer` is fully `accessibilityHidden(true)`.** VoiceOver
  users get no "loading…" announcement when the entry detail is
  fetching. Consider adding a manual announcement on transition into
  `.loading` state (e.g. via `accessibilityLabel("Loading entry")` on
  `LoadingPlaceholder`, or an `AccessibilityNotification.Announcement("Loading entry…")`
  from `EntryDetailModel` when the state transitions).
  — REMAINS OPEN (MVP 4 candidate)
- **System `confirmationDialog` (Delete, Reset to Defaults).** Trait
  presentation is system-provided; we have no test that asserts the
  destructive trait reaches the confirm button. Considered
  assumed-correct (system uses `Button(role: .destructive)`).
  — REMAINS OPEN (MVP 4 candidate)

## Trivial fixes applied during this audit

- **`Kizba/Presentation/Features/Sidebar/SidebarView.swift:44`** — added
  `.accessibilityLabel("\(folder.name), folder")` on each folder row
  so VoiceOver announces the semantic role. Without this, the leading
  `folder` icon (which is `.accessibilityHidden(true)`) leaves the
  row with no role context.

## How to run a quick a11y smoke

1. Toggle VoiceOver (⌘F5).
2. Launch Kizba.
3. Navigate the three columns with VO commands (Ctrl+Option+arrows).
4. Verify a folder row announces as `"<name>, folder"`.
5. Verify an entry row announces as `"<name>, <path>, selected"` (when
   selected).
6. Trigger a write (⌘N → fill → Save). Listen for the success toast
   announcement (should begin with "Success —").
7. In the entry detail, focus the password row. Confirm "Hidden secret"
   on first focus; toggle reveal; confirm the password is now read
   aloud.
8. Toggle Increase Contrast in System Settings → Accessibility →
   Display. Verify visual switch (deeper accent, heavier dividers).
9. Toggle Reduce Motion. Trigger a Regenerate. Verify no animations.
10. Bump text size to "Larger Accessibility Size 5" via System Settings
    → Accessibility → Display → Text Size. Verify EntryList rows still
    render readable; Settings labels truncate (known Medium gap).

## MVP 3 additions verified

- **Touch ID toggle (Settings):** VoiceOver announces label + state; disabled state announced when biometrics unavailable; reachable via keyboard Tab.
- **FSEvents auto-refresh:** Entry list updates automatically on external store change; no VoiceOver regression (new rows announced on focus).
- **SecureField password input (EntryFormBody):** Editable password field renders as `SecureField` by default; reveal toggle mirrors the read-only `SecretRevealField` vocabulary (`Hidden` / `Revealed`); defaults to masked so VoiceOver does not read individual characters as the user types. (Phase D.3 closure)
