//
//  DiagnosticsModelTests.swift
//  KizbaTests
//
//  Behavioural tests for `DiagnosticsModel` — the `@MainActor`
//  `@Observable` view-model that mirrors the in-memory
//  `InvocationLog` for the Diagnostics page (Phase 8.4).
//

import XCTest
@testable import Kizba

@MainActor
final class DiagnosticsModelTests: XCTestCase {

    private func makeInvocation(_ tag: String) -> Invocation {
        Invocation(
            executable: "/bin/echo",
            args: [tag],
            exitCode: 0,
            stderrExcerpt: "",
            startedAt: Date(),
            duration: 0.001
        )
    }

    func testRefreshLoadsRecent() async {
        let log = InvocationLog(maxEntries: 10)
        await log.record(makeInvocation("alpha"))
        await log.record(makeInvocation("beta"))

        let model = DiagnosticsModel(invocationLog: log)
        XCTAssertTrue(model.recentInvocations.isEmpty)

        await model.refresh()

        // Newest-first: "beta" then "alpha".
        XCTAssertEqual(model.recentInvocations.map { $0.args.first }, ["beta", "alpha"])
    }

    func testClearEmptiesModelAndLog() async {
        let log = InvocationLog(maxEntries: 5)
        await log.record(makeInvocation("a"))
        let model = DiagnosticsModel(invocationLog: log)
        await model.refresh()
        XCTAssertEqual(model.recentInvocations.count, 1)

        await model.clear()
        XCTAssertTrue(model.recentInvocations.isEmpty)

        // Confirm the underlying log was cleared too, not just the
        // local snapshot.
        let snapshot = await log.recent()
        XCTAssertTrue(snapshot.isEmpty)
    }
}
