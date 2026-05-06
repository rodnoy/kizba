# Kizba — Build Log

## 2026-05-06 — Step 0.3 verification

Host: macOS, Xcode 26.4.1 (17E202).

### Build

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **
```

### Test

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   KizbaTests.testExample            passed
   KizbaTests.testPerformanceExample passed
   2 tests, 0 failures
```

### Notes

- Project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16+ format), so
  the `Kizba/` and `KizbaTests/` source trees are picked up from disk
  automatically — no PBXFileReference / PBXBuildFile edits were needed for
  the file move or new folders.
- A single `PBXFileSystemSynchronizedBuildFileExceptionSet` was added to
  exclude `.keep` placeholder files from the `Kizba` target's bundle
  resources (otherwise Xcode would copy each one to
  `Kizba.app/Contents/Resources/.keep` and conflict on the identical
  output path).
- `Kizba/Assets.xcassets/` was relocated to `Kizba/Resources/Assets.xcassets/`
  to match the planned layout. Asset catalog lookup is by name
  (`ASSETCATALOG_COMPILER_APPICON_NAME` / `..._ACCENT_COLOR_NAME`), so the
  move is transparent.
