import XCTest
@testable import Kizba

@MainActor
final class GitStatusModelObserveTests: XCTestCase {

    func testObserveChanges_triggersLoadOnEvent() async {
        let mock = MockPassManager.preview()
        let fake = FakePassGitManager()
        await fake.setNextStatus(.success(makeMainStatus()))

        let appState = AppState(passManager: mock)
        let router = AppRouter()
        let toastCenter = ToastCenter()
        let model = GitStatusModel(
            gitManager: fake,
            passManager: mock,
            appState: appState,
            router: router,
            toastCenter: toastCenter
        )

        let observer = await startObservation(model: model)

        await mock.emitBulk()
        await waitUntil(
            { await fake.statusCallCount > 0 || model.loadState == .loaded },
            timeout: 1.0,
            message: "observeChanges did not trigger loadStatus on StoreChange"
        )

        let statusCallCount = await fake.statusCallCount
        XCTAssertEqual(statusCallCount, 1)
        XCTAssertEqual(model.status.branch, "main")

        model.stop()
        observer.cancel()
        await observer.value
    }

    func testStop_cancelsSubscription() async {
        let mock = MockPassManager(entries: [], secrets: [:])
        let fake = FakePassGitManager()
        await fake.setNextStatus(.success(makeMainStatus()))

        let appState = AppState(passManager: mock)
        let model = GitStatusModel(
            gitManager: fake,
            passManager: mock,
            appState: appState,
            router: AppRouter(),
            toastCenter: ToastCenter()
        )

        let observer = await startObservation(model: model)

        await mock.emitBulk()
        await waitUntil(
            { await fake.statusCallCount == 1 },
            timeout: 1.0,
            message: "baseline event did not trigger expected initial load"
        )

        model.stop()
        await observer.value

        await mock.emitBulk()
        try? await Task.sleep(for: .milliseconds(150))
        let statusCallCount = await fake.statusCallCount
        XCTAssertEqual(statusCallCount, 1)
    }

    func testObserveChanges_noDoubleSubscribe() async {
        let mock = MockPassManager(entries: [], secrets: [:])
        let fake = FakePassGitManager()
        await fake.setNextStatus(.success(makeMainStatus()))

        let appState = AppState(passManager: mock)
        let model = GitStatusModel(
            gitManager: fake,
            passManager: mock,
            appState: appState,
            router: AppRouter(),
            toastCenter: ToastCenter()
        )

        let observer = await startObservation(model: model)

        let secondReturned = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                await model.observeChanges()
                return true
            }
            group.addTask {
                try? await Task.sleep(for: .milliseconds(100))
                return false
            }
            let outcome = await group.next() ?? false
            group.cancelAll()
            return outcome
        }

        XCTAssertTrue(secondReturned)

        await mock.emitBulk()
        await waitUntil(
            { await fake.statusCallCount == 1 },
            timeout: 1.0,
            message: "single StoreChange should produce exactly one load"
        )

        model.stop()
        observer.cancel()
        await observer.value
    }

    func testObserveChanges_handlesCancellationDuringLoad() async {
        let mock = MockPassManager(entries: [], secrets: [:])
        let fake = FakePassGitManager()
        await fake.setNextStatus(.success(makeMainStatus()))
        await fake.setArtificialDelay(.seconds(1))

        let appState = AppState(passManager: mock)
        let model = GitStatusModel(
            gitManager: fake,
            passManager: mock,
            appState: appState,
            router: AppRouter(),
            toastCenter: ToastCenter()
        )

        let observer = await startObservation(model: model)

        await mock.emitBulk()
        await waitUntil(
            { await fake.statusCallCount > 0 },
            timeout: 1.0,
            message: "StoreChange did not start slow gitStatus load"
        )

        model.stop()
        observer.cancel()
        await observer.value

        let countAfterStop = await fake.statusCallCount
        await mock.emitBulk()
        try? await Task.sleep(for: .milliseconds(200))

        let statusCallCount = await fake.statusCallCount
        XCTAssertEqual(statusCallCount, countAfterStop)
        XCTAssertNotEqual(model.loadState, .loading)
    }

    private func makeMainStatus() -> GitStatus {
        GitStatus(
            isGitRepository: true,
            branch: "main",
            hasLocalChanges: false,
            hasConflicts: false,
            aheadCount: 0,
            behindCount: 0,
            hasRemote: true,
            lastFetchAt: nil
        )
    }
}
