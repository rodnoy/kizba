//
//  DestructiveConfirmationTests.swift
//  KizbaTests
//
//  Phase C.2: the modifier wraps SwiftUI's `confirmationDialog`. Snapshot
//  / interaction tests are out of scope per `.ai/decisions.md`, so this
//  file pins the public API surface — both `destructiveConfirmation` and
//  `overwriteConfirmation` must remain callable with the documented
//  signature so write-flow callers (Phase F / G) can rely on it.
//
//  The two-step nature is implicit in `confirmationDialog`'s system
//  behaviour; we trust the system for that.
//

import SwiftUI
import XCTest
@testable import Kizba

final class DestructiveConfirmationTests: XCTestCase {

    func testDestructiveConfirmation_isCallableWithDocumentedSignature() {
        // The modifier must accept (isPresented, title, message, confirm)
        // and return some View. The wrapping `_ = ...` exists purely to
        // exercise the call site; nothing renders.
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        _ = EmptyView()
            .destructiveConfirmation(
                isPresented: binding,
                title: "Delete?",
                message: "This cannot be undone.",
                confirm: {}
            )
    }

    func testDestructiveConfirmation_isCallableWithoutMessage() {
        // The `message` argument is optional with a `nil` default.
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        _ = EmptyView()
            .destructiveConfirmation(
                isPresented: binding,
                title: "Delete?",
                confirm: {}
            )
    }

    func testDestructiveConfirmation_acceptsCustomConfirmLabel() {
        // The default confirm label is "Delete"; callers may override it
        // (e.g. "Remove", "Discard"). This pins the param surface.
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        _ = EmptyView()
            .destructiveConfirmation(
                isPresented: binding,
                title: "Discard changes?",
                message: nil,
                confirmLabel: "Discard",
                confirm: {}
            )
    }

    func testOverwriteConfirmation_isCallableWithDocumentedSignature() {
        // Sister modifier — same shape, default confirm label is
        // "Overwrite", confirm button uses the default (non-destructive)
        // role because the action replaces, not deletes.
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        _ = EmptyView()
            .overwriteConfirmation(
                isPresented: binding,
                title: "Entry exists",
                message: "Replace existing entry?",
                confirm: {}
            )
    }

    func testOverwriteConfirmation_acceptsCustomConfirmLabel() {
        var flag = false
        let binding = Binding<Bool>(get: { flag }, set: { flag = $0 })
        _ = EmptyView()
            .overwriteConfirmation(
                isPresented: binding,
                title: "Replace?",
                confirmLabel: "Replace",
                confirm: {}
            )
    }
}
