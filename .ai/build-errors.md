Build failure during C.3 implementation (FSEventsStoreWatcher)

Summary:
- Implemented Kizba/Infrastructure/Store/FSEventsStoreWatcher.swift and opt-in test KizbaTests/FSEventsStoreWatcherTests.swift.
- Compilation fails when building the Kizba target. Multiple Swift concurrency/isolation errors occur related to Sendable/nonisolated usage and use of UnsafeMutablePointer in the watcher implementation.

Key errors (abbreviated):
- "'nonisolated' can not be applied to variable with non-'Sendable' type 'UnsafeMutablePointer<...>'" (statePtr)
- "Non-Sendable type 'UnsafeMutablePointer<...>' of property 'statePtr' cannot exit nonisolated context"
- "main actor-isolated property 'stream' can not be mutated from a Sendable closure"
- Various notes about 'nonisolated(unsafe)' having no effect on instance method 'emit()' and capture-of-self in deinit.

Cause notes:
- The implementation attempted to manage mutable internal state off the main actor using unsafe pointers and nonisolated annotations to avoid Swift's MainActor default isolation and Sendable checks. The Swift 6 concurrency model (and the project's compiler flags) prevent applying 'nonisolated' to mutable non-Sendable stored properties and disallow exiting nonisolated contexts with non-Sendable pointer types. Reconciling these constraints requires a different, careful threading-safe pattern (for example an actor-based design, or fully queue-confined properties without unsafe pointers) and careful protocol isolation design.

Next steps:
- This is a non-trivial concurrency/ABI/Sendable issue which requires design review. I will stop here and leave the branch in WIP state for an explicit follow-up.

Relevant artifacts & logs:
- Last commit: 4c79344 (feat(mvp3): add FSEventsStoreWatcher (C.3))
- xcodebuild output captured during the run; key errors excerpted above. Full build log available in CI/workspace when needed.
