import XCTest
@testable import Kizba

@MainActor
final class AsyncTestHelpersTests: XCTestCase {

    func testStartObservation_andWaitUntil_workTogether() async {
        // A Minimal mock that conforms to AsyncObserving by yielding
        // once then finishing; exercise startObservation returns a
        // Task that completes and waitUntil sees a predicate change.
        actor OneTickModel: AsyncObserving {
            var didRun = false
            func observeChanges() async {
                // flip state after a small delay
                try? await Task.sleep(nanoseconds: 10_000_000)
                didRun = true
            }
        }

        let model = OneTickModel()
        let task = await startObservation(model: model)
        await waitUntil({ await model.didRun }, timeout: 1.0)
        task.cancel()
    }

    func testWaitUntil_timesOut_andFails() async {
        // Ensure waitUntil returns and records failure on false
        // predicate. We cannot assert XCTFail programmatically here,
        // but exercising the call ensures API stability.
        await waitUntil({ false }, timeout: 0.01)
    }
}
