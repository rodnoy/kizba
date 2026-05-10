Swift/Xcode test runner not available in this environment. Verification commands failed.

Attempted command:
  swift test --filter KeyValueEditorAccessibilityTests

Output (truncated to 200 lines):
error: Could not find Package.swift in this directory or any of its parent directories.

No xcodebuild invocation was run because this environment does not expose Xcode project tooling.

Next steps:
- Run the focused test locally via xcodebuild for the Kizba Xcode project:
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/KeyValueEditorAccessibilityTests
- Run SourceGrepTests similarly, then run full suite.
