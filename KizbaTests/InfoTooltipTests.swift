//
//  InfoTooltipTests.swift
//  KizbaTests
//
//  MVP6.B.1 — pins the public API surface of `InfoTooltip` and the
//  `FormFieldRow` priority contract for `infoText` / `helpText` /
//  `errorText`.
//
//  Coverage:
//  - InfoTooltip initialisers (with and without a `title`) are callable
//    via every public surface. SwiftUI `@State` is private and Kizba
//    does not vendor ViewInspector, so internal popover state is
//    covered manually — the tests here lock the construction contract
//    so future refactors cannot silently drop a parameter.
//  - FormFieldRow.resolvedHelperText (pure) encodes the suppression
//    rule: `errorText` wins, `infoText` suppresses `helpText`,
//    otherwise `helpText` shows. This is what backs B.4's rollout.
//  - FormFieldRow.defaultInfoAccessibilityLabel composes a contextual
//    fallback label when the caller omits one.
//

import SwiftUI
import XCTest
@testable import Kizba

final class InfoTooltipTests: XCTestCase {

    // MARK: - InfoTooltip construction smoke

    func testInfoTooltip_initializesWithoutTitle() {
        // Minimal (text, accessibilityLabel) signature must remain
        // callable without supplying `title:`.
        _ = InfoTooltip(
            text: "Explains the field.",
            accessibilityLabel: "Help for field"
        )
    }

    func testInfoTooltip_initializesWithTitle() {
        // Optional `title` parameter must remain callable.
        _ = InfoTooltip(
            text: "Explains the field.",
            accessibilityLabel: "Help for field",
            title: "About this setting"
        )
    }

    func testInfoTooltip_initializesWithEmptyStrings() {
        // Empty strings are degenerate but legal — the component must
        // not require non-empty input to remain composable.
        _ = InfoTooltip(text: "", accessibilityLabel: "")
    }

    // MARK: - FormFieldRow.resolvedHelperText priority contract

    func testResolvedHelperText_returnsErrorText_whenErrorIsSet() {
        XCTAssertEqual(
            FormFieldRow<EmptyView>.resolvedHelperText(
                helpText: "help",
                errorText: "error",
                infoText: nil
            ),
            "error"
        )
    }

    func testResolvedHelperText_errorWinsOverInfoAndHelp() {
        // Even when both `infoText` and `helpText` are present, an
        // explicit `errorText` must take priority below the row.
        XCTAssertEqual(
            FormFieldRow<EmptyView>.resolvedHelperText(
                helpText: "help",
                errorText: "boom",
                infoText: "info"
            ),
            "boom"
        )
    }

    func testResolvedHelperText_suppressesHelpText_whenInfoTextIsSet() {
        // The tooltip is the new home for explanatory copy — the inline
        // helper line must NOT render when `infoText` is provided.
        XCTAssertNil(
            FormFieldRow<EmptyView>.resolvedHelperText(
                helpText: "help",
                errorText: nil,
                infoText: "info"
            )
        )
    }

    func testResolvedHelperText_returnsHelpText_whenOnlyHelpIsSet() {
        XCTAssertEqual(
            FormFieldRow<EmptyView>.resolvedHelperText(
                helpText: "help",
                errorText: nil,
                infoText: nil
            ),
            "help"
        )
    }

    func testResolvedHelperText_returnsNil_whenAllInputsAreNil() {
        XCTAssertNil(
            FormFieldRow<EmptyView>.resolvedHelperText(
                helpText: nil,
                errorText: nil,
                infoText: nil
            )
        )
    }

    // MARK: - FormFieldRow.defaultInfoAccessibilityLabel

    func testDefaultInfoAccessibilityLabel_includesFieldLabel() {
        // The fallback must be contextual rather than generic so
        // VoiceOver announces which field the info applies to.
        let result = FormFieldRow<EmptyView>.defaultInfoAccessibilityLabel(
            for: "Clipboard auto-clear delay"
        )
        XCTAssertTrue(
            result.contains("Clipboard auto-clear delay"),
            "expected default a11y label to include field name, got: \(result)"
        )
    }

    // MARK: - FormFieldRow constructor smoke (additive parameters)

    func testFormFieldRow_initWithInfoText_isCallable() {
        // Verifies the additive `infoText:` parameter is wired into the
        // public init without breaking existing keyword call-sites.
        _ = FormFieldRow(
            label: "Field",
            infoText: "Explains the field."
        ) {
            EmptyView()
        }
    }

    func testFormFieldRow_initWithInfoTextAndAccessibilityLabel_isCallable() {
        _ = FormFieldRow(
            label: "Field",
            infoText: "Explains the field.",
            infoAccessibilityLabel: "Help for Field"
        ) {
            EmptyView()
        }
    }

    func testFormFieldRow_existingCallSitesRemainCompatible() {
        // Legacy call-sites that pass only `label:` / `helpText:` /
        // `errorText:` must continue to compile unchanged after B.1.
        _ = FormFieldRow(label: "Field") { EmptyView() }
        _ = FormFieldRow(label: "Field", helpText: "help") { EmptyView() }
        _ = FormFieldRow(label: "Field", errorText: "error") { EmptyView() }
        _ = FormFieldRow(
            label: "Field",
            helpText: "help",
            errorText: "error"
        ) { EmptyView() }
    }
}
