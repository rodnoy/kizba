//
//  EmptyStateViewTests.swift
//  KizbaTests
//
//  Phase C.2: `EmptyStateView` is a pure presentational shell with no
//  testable pure helpers (the rendering is the spec). These tests pin
//  the public API surface — both initialisers must remain callable —
//  so future refactors don't silently break callers.
//

import SwiftUI
import XCTest
@testable import Kizba

final class EmptyStateViewTests: XCTestCase {

    func testEmptyStateView_initWithoutActions_isCallable() {
        // The `Actions == EmptyView` overload must accept the minimal
        // (icon, title) signature without requiring a trailing closure.
        _ = EmptyStateView(iconName: "tray", title: "Empty")
    }

    func testEmptyStateView_initWithoutActions_acceptsOptionalMessage() {
        _ = EmptyStateView(
            iconName: "tray",
            title: "Empty",
            message: "Nothing to show here."
        )
    }

    func testEmptyStateView_initWithActions_isCallable() {
        // The generic `Actions: View` initialiser accepts a `@ViewBuilder`
        // closure for trailing buttons / links.
        _ = EmptyStateView(
            iconName: "tray",
            title: "Empty",
            message: "Add something.",
            actions: { Button("Add") {} }
        )
    }

    func testEmptyStateView_initWithActions_messageIsOptional() {
        _ = EmptyStateView(
            iconName: "tray",
            title: "Empty",
            actions: { Button("Add") {} }
        )
    }
}
