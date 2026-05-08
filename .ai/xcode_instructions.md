Release binary audit

This section documents a simple CI-friendly audit to ensure that no
debug-only fixture secrets or text tokens (used by MockPassManager
fixtures) are present in the Release binary. It is intended to be run
against a Release build artifact in your CI pipeline. The repository
also contains a small compile-time test (KizbaTests/ReleaseBinaryTests.swift)
which asserts that MockPassManager.swift is guarded by #if DEBUG;
the `strings` audit below provides a runtime verification on the built
product.

# Build Release
xcodebuild -scheme Kizba -configuration Release -derivedDataPath ./build -destination 'platform=macOS' clean build

# Locate built app and binary
APP=$(find ./build -name "Kizba.app" -type d | head -n 1)
BINARY="$APP/Contents/MacOS/Kizba"

# Search for fixture tokens (fail if any found)
strings "$BINARY" | egrep -i 'p4ss-|correct horse|fixture|ghp_' && { echo "Fixture tokens found in release binary"; exit 1; } || echo "No fixture tokens found"

Notes:
- Run this check in CI after building the Release configuration.
- The compile-time test added to KizbaTests ensures MockPassManager
  stays behind #if DEBUG; the strings check validates that no fixture
  tokens leaked into the final binary artifact.
