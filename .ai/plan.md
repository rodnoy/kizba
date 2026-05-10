# C.5 — LivePassManager ↔ StoreWatching Integration

## Goal

Wire `StoreWatching` into `LivePassManager` so that filesystem change events from the watcher are automatically emitted as `.bulk` `StoreChange` events to all subscribers. The watcher lifecycle is lazy: starts on first subscriber registration, stops on last unsubscription.

## Constraints

- `LivePassManager` is an `actor` — all new state is actor-isolated.
- Watcher is injected via an optional init parameter (`storeWatcher: (any StoreWatching)? = nil`) for backward compatibility.
- No refactoring of unrelated code.
- Tests use `FakeStoreWatcher` (existing fixture at `KizbaTests/Fixtures/FakeStoreWatcher.swift`).
- Tests must be deterministic and fast (no `sleep`, only small expectation timeouts).
- `SWIFT_STRICT_CONCURRENCY = complete`.

## Tasks

### Task 1 — Modify `LivePassManager` init + stored properties

- **Objective:** Add watcher support to `LivePassManager`.
- **Files to modify:** `Kizba/Infrastructure/Pass/LivePassManager.swift`
- **Changes:**
  1. Add stored property: `private let storeWatcher: (any StoreWatching)?`
  2. Add stored property: `private var watcherDrainTask: Task<Void, Never>?` — holds the task draining `watcher.events`.
  3. Add stored property: `private var watcherStarted: Bool = false` — guards against double-start.
  4. Update designated `init(scanner:passCLI:storeRootProvider:)` to accept `storeWatcher: (any StoreWatching)? = nil` as a 4th parameter (default `nil`). Store it.
  5. Update convenience `init(scanner:passCLI:storeRoot:)` to forward `storeWatcher: nil` (or accept and forward it too — prefer forwarding for test flexibility: `storeWatcher: (any StoreWatching)? = nil`).
- **Verification:** Project compiles. All existing `LivePassManagerTests`, `LivePassManagerWriteTests`, `LivePassManagerStoreOverrideTests` pass unchanged (default `nil` watcher).
- **Risks:** Init signature change could break existing call sites — mitigated by default `nil`.

### Task 2 — Implement lazy watcher start/stop in register/unregister

- **Objective:** Start watcher on first subscriber, stop on last.
- **Files to modify:** `Kizba/Infrastructure/Pass/LivePassManager.swift`
- **Changes:**
  1. In `register(id:continuation:)` — after adding to `continuations`, check: if `continuations.count == 1` AND `storeWatcher != nil` AND `!watcherStarted`, then:
     - Set `watcherStarted = true`
     - Call `await storeWatcher!.start(at: storeRootProvider())`
     - Spawn `watcherDrainTask = Task { [weak self] in ... }` that iterates `storeWatcher!.events` and for each event calls `await self?.handleWatcherEvent()`. The task must check `Task.isCancelled` and break on cancellation.
  2. Add private method `handleWatcherEvent()` that calls `let root = storeRootProvider(); await scanner.invalidate(storeRoot: root); emit(.bulk)`. Scanner invalidation before emit preserves the ordering invariant (subscribers re-listing see post-change state).
  3. In `unregister(id:)` — after removing from `continuations`, check: if `continuations.isEmpty` AND `watcherStarted`, then:
     - Cancel `watcherDrainTask` and set to `nil`.
     - Call `await storeWatcher?.stop()`
     - Set `watcherStarted = false`
  4. Note: `register` is already actor-isolated, so all state mutations are safe. The `Task` spawned for draining runs on the actor's executor (not detached), so `handleWatcherEvent()` calls are serialized.
- **Verification:** Project compiles. Existing tests pass.
- **Risks:** `register` is currently sync (no `async`). It needs to become `async` to call `watcher.start(at:)`. The call site in `changes` getter already does `await self?.register(...)` inside a `Task`, so this is compatible. Same for `unregister` → needs `async` for `watcher.stop()`.

### Task 3 — Create `LivePassManagerFSEventsTests`

- **Objective:** Verify watcher integration with ≥ 6 test methods using `FakeStoreWatcher`.
- **Files to add:** `KizbaTests/LivePassManagerFSEventsTests.swift`
- **Test infrastructure:** Each test creates a `FakeStoreWatcher`, a `FakePasswordStoreScanner` (or whatever scanner fake exists), a `LivePassCLI` over a `FakeShellRunner`, and a `LivePassManager(scanner:passCLI:storeRootProvider:storeWatcher:)`. Tests subscribe to `manager.changes` via `Task` and collect events.
- **Test cases (6+):**

  1. **`testWatcherStartsOnFirstSubscriber`** — Subscribe once to `manager.changes`. Yield to let registration complete. Assert `watcher.getStartCount() == 1`.

  2. **`testWatcherDoesNotDoubleStartOnSecondSubscriber`** — Subscribe twice. Yield. Assert `watcher.getStartCount() == 1` (not 2).

  3. **`testWatcherStopsOnLastUnsubscribe`** — Subscribe once, cancel the consuming task (drops the iterator → `onTermination` fires → `unregister`). Wait briefly. Assert `watcher.getStopCount() == 1`.

  4. **`testWatcherDoesNotStopWhileSubscribersRemain`** — Subscribe twice. Cancel one. Assert `watcher.getStopCount() == 0`. Cancel the other. Assert `watcher.getStopCount() == 1`.

  5. **`testBulkEmissionOnSimulateChange`** — Subscribe, wait for registration, call `watcher.simulateChange()`. Assert the subscriber receives `.bulk`.

  6. **`testMultipleBulkEmissions`** — Subscribe, simulate 3 changes. Assert subscriber receives 3 `.bulk` events.

  7. **`testNoWatcherWhenNilInjected`** (optional 7th) — Create manager with `storeWatcher: nil`. Subscribe. Assert no crash, no watcher interaction. Events from write methods still work.

- **Verification:** `xcodebuild test -only-testing:KizbaTests/LivePassManagerFSEventsTests` — all pass.
- **Risks:** Registration is async (Task hop in `changes` getter). Tests need `Task.yield()` calls (or the existing `startObservation` helper from `AsyncTestHelpers`) to ensure registration completes before assertions. Use the established pattern from `EntryListReconciliationTests`.

### Task 4 — Verify existing tests still pass

- **Objective:** Ensure no regressions.
- **Files to modify:** None.
- **Verification:**
  - `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LivePassManagerTests` — pass
  - `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LivePassManagerWriteTests` — pass
  - `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LivePassManagerStoreOverrideTests` — pass
  - `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LivePassManagerFSEventsTests` — pass (new)
  - Full suite: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'` — all pass, 0 failures
- **Risks:** None if Tasks 1–3 are correct.

## Implementation Notes

### Concurrency details

- `register` and `unregister` are actor-isolated methods. They become `async` (they already were effectively async since callers `await` them).
- The drain task is a regular `Task` (not `.detached`) so it inherits the actor's executor. Each iteration of `for await _ in watcher.events` suspends; on resume, `handleWatcherEvent()` runs on the actor — no data races.
- `watcherStarted` bool prevents double-start even if two registrations race (actor serializes them).
- On last unsubscribe: cancel drain task first (so it won't try to emit after continuations are gone), then stop watcher.

### Scanner invalidation on watcher events

- `handleWatcherEvent()` calls `scanner.invalidate(storeRoot:)` before `emit(.bulk)` — same ordering invariant as write methods. This ensures subscribers that re-list in response to `.bulk` see fresh FS state.

## Commit message

```
feat(mvp3): integrate StoreWatching into LivePassManager (C.5)

Add optional `storeWatcher` parameter to LivePassManager init.
Watcher starts lazily on first subscriber registration and stops
on last unsubscription. Watcher events drain into `.bulk` StoreChange
emissions with scanner invalidation before emit.

LivePassManagerFSEventsTests: 7 test methods using FakeStoreWatcher
verify lazy start, no double-start, stop on last unsubscribe,
bulk emission on simulateChange, and nil-watcher safety.
```

## Suggested current step

Begin with Task 1 (init signature change), then Task 2 (register/unregister wiring), then Task 3 (tests). Task 4 is verification only.
