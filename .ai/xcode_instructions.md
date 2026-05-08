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

Notarization

This project is distributed outside the App Store using Developer ID
distribution. The expected high-level notarization workflow is:

- Archive the app from Xcode (or with xcodebuild).
- Export a Developer ID signed artifact (.app or .pkg) with the
  Developer ID Application signing identity and Hardened Runtime
  enabled (entitlements documented elsewhere).
- Submit the exported artifact to Apple's notarization service via
  xcrun notarytool and wait for completion.
- Staple the notarization ticket into the shipped app with stapler.

Recommended CI-friendly commands (example placeholders):

1) Archive

xcodebuild -scheme Kizba -configuration Release -archivePath ./build/Kizba.xcarchive archive

2) Export (Developer ID signed .app or .pkg)

xcodebuild -exportArchive -archivePath ./build/Kizba.xcarchive -exportPath ./build/export -exportOptionsPlist ./ExportOptions.plist

Note: ExportOptions.plist must be configured for developer-id
distribution (Developer ID Application signing, appropriate
signingStyle, and the Hardened Runtime entitlements).

3) Zip and submit to notarytool (API key preferred; show both examples)

# Create a zip of the exported app (notarytool accepts zip/pkg)
zip -r ./build/export/Kizba.zip ./build/export/Kizba.app

# Using API key (recommended for CI)
xcrun notarytool submit ./build/export/Kizba.zip --key /path/to/AuthKey.p8 --key-id <KEY_ID> --issuer <ISSUER_ID> --wait

# Using Apple ID (less preferred; credentials should come from CI secrets)
xcrun notarytool submit ./build/export/Kizba.zip --apple-id "EMAIL" --password "@keychain:AC_PASSWORD" --wait

4) Staple the notarization ticket

xcrun stapler staple ./build/export/Kizba.app

Verify notarization status (local check)

xcrun stapler validate ./build/export/Kizba.app

Notes and recommendations:
- Prefer xcrun notarytool with an API key in CI. Do NOT commit
  secrets or API keys to the repository. Use your CI provider's
  secret store or the macOS keychain in runners.
- Developer ID Application signing and Hardened Runtime are required
  for notarization and are documented elsewhere in these
  instructions (entitlements / Signing & Capabilities). Ensure the
  entitlements file and ExportOptions.plist are correctly configured
  before exporting.
- Run the strings-audit step (see "Release binary audit" above) after
  export and before submitting to notarization as a final gate that
  the exported Release artifact contains no debug fixtures or secrets.
