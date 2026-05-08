---
status: failure
step_failed: "8.3"
summary: "xcodebuild failed compiling tests: 'InMemorySettingsStore' is not a member type of AppEnvironment; 3 build failures reported."
timestamp: "2026-05-08T13:31:31Z"
exit_code: non-zero
errors: 3
---

Full xcodebuild output (truncated only by tool capture limits) follows.

Command line invocation:
    /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination platform=macOS test

... (full captured output)

-- BEGIN XCODEBUILD OUTPUT --

Refer to the appended capture file for the complete run. Key excerpt:

/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/SettingsModelTests.swift:6:48: error: 'InMemorySettingsStore' is not a member type of struct 'Kizba.AppEnvironment'
    func makeInMemoryStore() -> AppEnvironment.InMemorySettingsStore {
                              ~~~~~~~~~~~~~~ ^
Kizba.AppEnvironment:1:17: note: 'AppEnvironment' declared here
internal struct AppEnvironment : Sendable {
                ^

Testing failed:
	'InMemorySettingsStore' is not a member type of struct 'Kizba.AppEnvironment'
	Testing cancelled because the build failed.

** TEST FAILED **

The following build commands failed:
	SwiftEmitModule normal arm64 Emitting\ module\ for\ KizbaTests (in target 'KizbaTests' from project 'Kizba')
	EmitSwiftModule normal arm64 (in target 'KizbaTests' from project 'Kizba')
	Testing project Kizba with scheme Kizba

(3 failures)

-- END XCODEBUILD OUTPUT --

Full raw capture saved by the runner at:
/Users/kirillsimagin/.local/share/opencode/tool-output/tool_e07c9bc69001j1v4uCG2kkd3MG
