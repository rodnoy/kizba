//
//  ToastCenterTests.swift
//  KizbaTests
//
//  Tests for the `@Observable @MainActor` toast coordinator. Covers
//  the post / dedup / pre-empt / auto-dismiss / manual-dismiss
//  contract documented in `Kizba/Presentation/Toast/ToastCenter.swift`.
//
//  All time-dependent assertions use the real `ContinuousClock` (no
//  clock injection in F.1; see step report). Sleeps use generous
//  margins (~150ms slack) to avoid flapping under CI load while still
//  keeping the suite fast (the longest test sleeps ~1.2 s).
//

import XCTest
@testable import Kizba

@MainActor
final class ToastCenterTests: XCTestCase {

    // MARK: - Default duration policy

    func testDefaultDuration_nonActionable_isFourSeconds() {
        let toast = Toast(severity: .info, title: "x")
        XCTAssertEqual(toast.duration, .seconds(4))
    }

    func testDefaultDuration_actionable_isTenSeconds() {
        let action = BannerView.BannerAction(label: "Undo") {}
        let toast = Toast(severity: .success, title: "x", action: action)
        XCTAssertEqual(toast.duration, .seconds(10))
    }

    func testExplicitDuration_overridesDefault() {
        let toast = Toast(severity: .info, title: "x", duration: .seconds(99))
        XCTAssertEqual(toast.duration, .seconds(99))
    }

    // MARK: - Post / visible

    func testPost_setsVisibleToPostedToast() {
        let center = ToastCenter()
        let t = Toast(severity: .success, title: "Saved")
        center.post(t)
        XCTAssertEqual(center.visible?.id, t.id)
        XCTAssertEqual(center.visible?.title, "Saved")
    }

    // MARK: - Auto-dismiss

    func testAutoDismiss_clearsVisibleAfterDuration() async throws {
        let center = ToastCenter()
        let t = Toast(
            severity: .info,
            title: "quick",
            duration: .milliseconds(50)
        )
        center.post(t)
        XCTAssertEqual(center.visible?.id, t.id)

        // Wait well past the duration so the dismiss task lands.
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertNil(center.visible, "toast should auto-dismiss after its duration")
    }

    // MARK: - Manual dismiss

    func testDismiss_matchingID_clearsVisible() {
        let center = ToastCenter()
        let t = Toast(severity: .info, title: "x", duration: .seconds(60))
        center.post(t)
        XCTAssertNotNil(center.visible)

        center.dismiss(t.id)
        XCTAssertNil(center.visible)
    }

    func testDismiss_nonMatchingID_isNoOp() {
        let center = ToastCenter()
        let t = Toast(severity: .info, title: "x", duration: .seconds(60))
        center.post(t)

        center.dismiss(UUID()) // wrong id
        XCTAssertEqual(center.visible?.id, t.id)
    }

    // MARK: - Dedup

    func testDedup_identicalPostWithinWindow_isDropped() {
        let center = ToastCenter()
        let first = Toast(severity: .success, title: "Saved", message: "ok", duration: .seconds(60))
        let second = Toast(severity: .success, title: "Saved", message: "ok", duration: .seconds(60))

        center.post(first)
        center.post(second)

        XCTAssertEqual(
            center.visible?.id, first.id,
            "second identical post within 1s window should be dropped silently"
        )
    }

    func testDedup_distinguishesByMessage() {
        let center = ToastCenter()
        let a = Toast(severity: .success, title: "ok", message: "a", duration: .seconds(60))
        let b = Toast(severity: .success, title: "ok", message: "b", duration: .seconds(60))

        center.post(a)
        center.post(b)

        XCTAssertEqual(
            center.visible?.id, b.id,
            "different message should bypass dedup and pre-empt the first toast"
        )
    }

    func testDedup_distinguishesBySeverity() {
        let center = ToastCenter()
        let info = Toast(severity: .info, title: "x", duration: .seconds(60))
        let success = Toast(severity: .success, title: "x", duration: .seconds(60))

        center.post(info)
        center.post(success)

        XCTAssertEqual(center.visible?.id, success.id)
    }

    func testDedup_expiresAfterOneSecond() async throws {
        let center = ToastCenter()
        let first = Toast(severity: .info, title: "ping", duration: .seconds(60))
        center.post(first)
        XCTAssertEqual(center.visible?.id, first.id)

        // Wait past the 1-second dedup window with margin.
        try await Task.sleep(for: .milliseconds(1200))

        let second = Toast(severity: .info, title: "ping", duration: .seconds(60))
        center.post(second)
        XCTAssertEqual(
            center.visible?.id, second.id,
            "post identical to a >1s-old one should be accepted"
        )
    }

    // MARK: - Pre-emption

    func testNewPost_preemptsCurrentlyVisible() {
        let center = ToastCenter()
        let a = Toast(severity: .info, title: "a", duration: .seconds(60))
        let b = Toast(severity: .warning, title: "b", duration: .seconds(60))

        center.post(a)
        XCTAssertEqual(center.visible?.id, a.id)

        center.post(b)
        XCTAssertEqual(
            center.visible?.id, b.id,
            "different content should immediately replace the visible toast"
        )
    }

    func testNewPost_cancelsPriorAutoDismissTask() async throws {
        let center = ToastCenter()

        // Toast A would auto-dismiss in 100 ms; B replaces it before
        // that timer fires. After 200 ms, B must still be visible —
        // i.e. A's dismiss task must have been cancelled, not just
        // shadowed.
        let a = Toast(severity: .info, title: "a", duration: .milliseconds(100))
        center.post(a)

        let b = Toast(severity: .warning, title: "b", duration: .seconds(60))
        center.post(b)

        try await Task.sleep(for: .milliseconds(250))

        XCTAssertEqual(
            center.visible?.id, b.id,
            "A's dismiss task must not clear B"
        )
    }

    // MARK: - Identity

    func testToast_freshIDPerInstance() {
        let a = Toast(severity: .info, title: "x")
        let b = Toast(severity: .info, title: "x")
        XCTAssertNotEqual(a.id, b.id)
    }
}
