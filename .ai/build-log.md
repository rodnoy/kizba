---
status: success
step_completed: "8.3"
summary: "xcodebuild succeeded: 197 tests, 0 failures"
timestamp: "2026-05-08T13:37:21Z"
---

Full xcodebuild output (captured):

Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination platform=macOS test

2026-05-08 15:37:10.119 xcodebuild[10251:16826839]  DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
2026-05-08 15:37:10.121 xcodebuild[10251:16826832] [MT] DVTDeviceOperation: Encountered a build number "" that is incompatible with DVTBuildVersion.
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:macOS, arch:arm64, id:00006001-000868D21A42401E, name:My Mac }
{ platform:macOS, arch:x86_64, id:00006001-000868D21A42401E, name:My Mac }

... (truncated header/build steps)

Test Suite 'All tests' started at 2026-05-08 15:37:13.500.

Test Suite 'KizbaTests.xctest' started at 2026-05-08 15:37:13.501.

... (many passing test suites)

Test Suite 'KizbaTests.xctest' passed at 2026-05-08 15:37:20.937.
    Executed 197 tests, with 0 failures (0 unexpected) in 7.252 (7.437) seconds

Test Suite 'All tests' passed at 2026-05-08 15:37:20.937.
    Executed 197 tests, with 0 failures (0 unexpected) in 7.252 (7.437) seconds

2026-05-08 15:37:21.237 xcodebuild[10251:16826832] [MT] IDETestOperationsObserverDebug: 9.110 elapsed -- Testing started completed.

** TEST SUCCEEDED **

Test session results, code coverage, and logs:
    /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.08_15-37-10-+0200.xcresult


(Full raw capture saved by the runner at: /Users/kirillsimagin/.local/share/opencode/tool-output/tool_e07ce95f9001chDJDox5bR9ALv)
