//
//  LogWrapperTests.swift
//  KizbaTests
//
//  Sanity checks for `Log`. The actual privacy-marker rendering
//  happens inside `os_log` at runtime and is not observable here, so
//  these tests focus on:
//
//  - The wrapper compiles and exposes the documented surface
//    (subsystem, all five categorised loggers).
//  - String interpolation with `privacy:` arguments compiles against
//    every category — guards against accidentally typing a category
//    as something other than `os.Logger`.
//  - `Log.redact(_:max:)` enforces its length cap.
//

import XCTest
import os
@testable import Kizba

final class LogWrapperTests: XCTestCase {

    func testSubsystemIdentifier() {
        XCTAssertEqual(Log.subsystem, "app.kizba")
    }

    func testCategoryLoggersAreDistinct() {
        // We cannot read the category back from `Logger`, but every
        // property must at least be reachable and accept the same
        // privacy-aware interpolation.
        let path = "/private/var/secret"
        let argc = 3
        let exitCode = 0

        Log.shell.debug(
            "exec=\(path, privacy: .private) argc=\(argc, privacy: .public) status=\(exitCode, privacy: .public)"
        )
        Log.pass.debug(
            "entry=\(path, privacy: .private) argc=\(argc, privacy: .public)"
        )
        Log.clipboard.debug(
            "token=\(argc, privacy: .public) changeCount=\(exitCode, privacy: .public)"
        )
        Log.discovery.debug(
            "candidate=\(path, privacy: .private)"
        )
        Log.ui.debug(
            "selection=\(path, privacy: .private)"
        )
    }

    // MARK: - redact

    func testRedactPassesShortStringThrough() {
        let input = "boom"
        XCTAssertEqual(Log.redact(input, max: 16), input)
    }

    func testRedactTruncatesLongString() {
        let input = String(repeating: "x", count: 200)
        let output = Log.redact(input, max: 32)
        XCTAssertEqual(output.count, 33) // 32 chars + ellipsis
        XCTAssertTrue(output.hasSuffix("…"))
        XCTAssertTrue(output.hasPrefix(String(repeating: "x", count: 32)))
    }

    func testRedactDefaultCap() {
        let input = String(repeating: "y", count: Log.maxStderrExcerpt + 100)
        let output = Log.redact(input)
        XCTAssertEqual(output.count, Log.maxStderrExcerpt + 1)
        XCTAssertTrue(output.hasSuffix("…"))
    }
}
