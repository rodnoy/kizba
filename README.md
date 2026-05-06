# Kizba

Native macOS SwiftUI GUI for the Unix [`pass`](https://www.passwordstore.org/)
password manager. MVP 1 is a read-only client with a three-column layout,
lazy decryption via `pass show`, and per-field copy with auto-clear.

See `.ai/plan.md` for the full implementation plan and `.ai/decisions.md`
for durable architectural decisions.

## Requirements

- macOS 14.0 or newer (deployment target).
- Xcode 15.4 or newer (Swift 5.10, strict concurrency = complete).
- For real (non-mock) decryption at runtime: `pass`, `gpg`, and
  `pinentry-mac` installed (e.g. via Homebrew).

## Project layout

The Xcode project is committed at the repo root:

- `Kizba.xcodeproj/` — Xcode project (Swift 5.10, macOS 14, strict
  concurrency, warnings-as-errors).
- `Kizba/` — application sources.
- `KizbaTests/` — XCTest target.

The project was created via the Xcode UI; the manual creation steps are
documented in [`.ai/xcode_instructions.md`](.ai/xcode_instructions.md).
The `Kizba` scheme is shared (`Kizba.xcodeproj/xcshareddata/xcschemes/`)
so that `xcodebuild` works out of the box on any clone.

## Quickstart

Build the app:

```sh
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' build
```

Run the test suite:

```sh
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
```

Run a single test bundle (example):

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests
```

## Logs

The most recent successful build/test run is recorded in
[`.ai/build-log.md`](.ai/build-log.md). Build failures, when present, are
captured in `.ai/build-errors.md`.

## License

TBD.
