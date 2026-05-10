xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FakeStoreWatcherTests

--- OUTPUT (truncated) ---
Test Case '-[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/FakeStoreWatcherTests.swift:66: error: -[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents] : failed - predicate did not become true in time
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/FakeStoreWatcherTests.swift:68: error: -[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents] : XCTAssertTrue failed
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/FakeStoreWatcherTests.swift:69: error: -[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents] : XCTAssertTrue failed
Test Case '-[KizbaTests.FakeStoreWatcherTests testMultipleSubscribersReceiveEvents]' failed (6.268 seconds).
Test Case '-[KizbaTests.FakeStoreWatcherTests testSimulateChangeEmitsEvent]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/FakeStoreWatcherTests.swift:35: error: -[KizbaTests.FakeStoreWatcherTests testSimulateChangeEmitsEvent] : failed - predicate did not become true in time
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/FakeStoreWatcherTests.swift:36: error: -[KizbaTests.FakeStoreWatcherTests testSimulateChangeEmitsEvent] : XCTAssertTrue failed
Test Case '-[KizbaTests.FakeStoreWatcherTests testSimulateChangeEmitsEvent]' failed (1.008 seconds).
Test Case '-[KizbaTests.FakeStoreWatcherTests testStartStopCounts]' started.
Test Case '-[KizbaTests.FakeStoreWatcherTests testStartStopCounts]' passed (0.002 seconds).
Test Suite 'FakeStoreWatcherTests' failed at 2026-05-10 14:59:01.350.
	Executed 3 tests, with 5 failures (0 unexpected) in 7.279 (7.281) seconds

See full xcodebuild log in the console output.
