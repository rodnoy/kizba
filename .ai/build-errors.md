# Build Errors — Step 8.3

**Date:** 2026-05-08T16:37:10+02:00
**Command:** `xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test`

## Error

```
Kizba/Presentation/Features/Settings/SettingsView.swift:29:88: error: cannot convert value of type 'String?' to expected argument type 'WritableKeyPath<SettingsModel, String?>'
    TextField("Password store path override", text: bindingForOptional(&model.storePathOverride))
```

## Analysis

The `bindingForOptional` helper expects a `WritableKeyPath<SettingsModel, String?>` but is called with `&model.storePathOverride` (an inout reference). This is a pre-existing compile error unrelated to the PlaygroundSupport fix. The `&` prefix passes an inout value, not a key path. The fix would be to use `\.storePathOverride` key path syntax instead of `&model.storePathOverride`.

## Fix applied in this session

- Removed `import PlaygroundSupport` and replaced preview provider with `AppEnvironment.preview()` + local `PreviewDiscovery` stub. (commit `abf55b2`)

## Remaining issue

- `bindingForOptional` call sites use `&model.property` instead of `\.property` key path syntax — affects lines 29, 39, 49, 55.
