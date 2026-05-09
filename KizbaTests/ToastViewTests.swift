//
//  ToastViewTests.swift
//  KizbaTests
//
//  Phase C.2 (bonus): locks the `ToastView` accessibility-label contract
//  via the pure helpers `severityLabel(for:)` and
//  `accessibilityLabel(for:title:message:)`. The visual icon and
//  background tokens are shared with `BannerView` and already covered
//  by `BannerViewTests`, so no duplication here.
//
//  The accessibility label is the primary VoiceOver surface for toasts
//  and is the only piece of the toast a screen-reader user perceives —
//  composition correctness matters.
//

import XCTest
@testable import Kizba

final class ToastViewTests: XCTestCase {

    // MARK: - severityLabel

    func testToastView_severityLabel_isCorrectPerSeverity() {
        XCTAssertEqual(ToastView.severityLabel(for: .info), "Info")
        XCTAssertEqual(ToastView.severityLabel(for: .success), "Success")
        XCTAssertEqual(ToastView.severityLabel(for: .warning), "Warning")
        XCTAssertEqual(ToastView.severityLabel(for: .danger), "Error")
    }

    func testToastView_severityLabel_isNonEmptyForEverySeverity() {
        for severity in BannerView.Severity.allCases {
            XCTAssertFalse(
                ToastView.severityLabel(for: severity).isEmpty,
                "severity label empty for \(severity)"
            )
        }
    }

    func testToastView_severityLabel_isUniquePerSeverity() {
        let labels = BannerView.Severity.allCases.map { ToastView.severityLabel(for: $0) }
        XCTAssertEqual(Set(labels).count, BannerView.Severity.allCases.count)
    }

    // MARK: - accessibilityLabel composition

    func testToastView_accessibilityLabel_includesSeverityAndTitleWhenMessageIsNil() {
        let label = ToastView.accessibilityLabel(
            for: .success,
            title: "Saved",
            message: nil
        )
        XCTAssertTrue(label.contains("Success"), "missing severity in '\(label)'")
        XCTAssertTrue(label.contains("Saved"), "missing title in '\(label)'")
    }

    func testToastView_accessibilityLabel_includesSeverityTitleAndMessageWhenAllPresent() {
        let label = ToastView.accessibilityLabel(
            for: .danger,
            title: "Failed",
            message: "Permission denied"
        )
        XCTAssertTrue(label.contains("Error"), "missing severity in '\(label)'")
        XCTAssertTrue(label.contains("Failed"), "missing title in '\(label)'")
        XCTAssertTrue(label.contains("Permission denied"), "missing message in '\(label)'")
    }

    func testToastView_accessibilityLabel_skipsEmptyMessage() {
        // An empty-string message is treated as "no message" so VoiceOver
        // doesn't read trailing punctuation with nothing after it.
        let withEmpty = ToastView.accessibilityLabel(
            for: .info,
            title: "Hello",
            message: ""
        )
        let withoutMessage = ToastView.accessibilityLabel(
            for: .info,
            title: "Hello",
            message: nil
        )
        XCTAssertEqual(withEmpty, withoutMessage)
    }

    func testToastView_accessibilityLabel_isStableAcrossSeverities() {
        // Sanity: every severity produces a non-empty label that contains
        // both its severity prefix and the title.
        for severity in BannerView.Severity.allCases {
            let label = ToastView.accessibilityLabel(
                for: severity,
                title: "Title",
                message: nil
            )
            XCTAssertFalse(label.isEmpty)
            XCTAssertTrue(label.contains(ToastView.severityLabel(for: severity)))
            XCTAssertTrue(label.contains("Title"))
        }
    }
}
