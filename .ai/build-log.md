Timestamp: 2026-05-17 13:15:40 +0200

Invocations run:
- xcodebuild clean build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/MenuBarModelTests -only-testing:KizbaTests/StatusItemControllerTests -only-testing:KizbaTests/SettingsModelTests -only-testing:KizbaTests/SourceGrepTests

Summary of captured console output (truncated xcresult binary parts):

-- BUILD (clean build) --

Output: BUILD SUCCEEDED
(Full build stdout/stderr captured into the tool output archive.)

-- FULL TEST SUITE --

Executed: xcodebuild test (full)
Result: ** TEST SUCCEEDED **
Tests: 999 executed, 17 skipped, 0 failures
Duration: ~44s
See: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.17_13-13-29-+0200.xcresult

Key console excerpts:
- Many unit test suites ran (ProcessShellRunnerTests, RecentsModelTests, RegenerateInPlaceModelTests, ...)
- Final line: ** TEST SUCCEEDED **

-- TARGETED TESTS (MenuBarModel + StatusItemController + SettingsModel + SourceGrep) --

Executed: xcodebuild test (targeted)
Result: ** TEST SUCCEEDED **
Tests: 40 executed, 0 failures
Duration: ~1.2s
See: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.17_13-15-34-+0200.xcresult

-- Grep checks --

rg -n '\bas!\b' Kizba/  => no matches
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/ => only matches in tests describing the grep rules (SourceGrepTests.swift), no infra source logging found

Notes:
- The xcresult bundles are binary; their full contents (attachments) are not included here. Only textual console output was captured and is included above.
