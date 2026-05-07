//
//  AppEnvironmentClipboardTests.swift
//  KizbaTests
//
//  Phase 7.2 wiring assertion: `AppEnvironment.live()` must inject the
//  production `ClipboardService` (the actor backed by
//  `SystemPasteboardAdapter`), while `AppEnvironment.preview()` must
//  inject a non-production double so previews/tests never reach for
//  the real `NSPasteboard`. No clipboard methods are invoked here.
//

import XCTest
@testable import Kizba

final class AppEnvironmentClipboardTests: XCTestCase {

    func testLive_clipboardIsProductionClipboardService() {
        let env = AppEnvironment.live()
        XCTAssertTrue(
            env.clipboard is ClipboardService,
            "live() must wire the production ClipboardService actor; got \(type(of: env.clipboard))."
        )
    }

    func testPreview_clipboardIsNotProductionService() {
        let env = AppEnvironment.preview()
        XCTAssertFalse(
            env.clipboard is ClipboardService,
            "preview() must wire a non-production clipboard double; got the live ClipboardService."
        )
    }

    func testLive_andPreview_clipboardsAreDistinctTypes() {
        let live = AppEnvironment.live().clipboard
        let preview = AppEnvironment.preview().clipboard
        XCTAssertNotEqual(
            String(describing: type(of: live)),
            String(describing: type(of: preview)),
            "live() and preview() must inject different clipboard implementations."
        )
    }
}
