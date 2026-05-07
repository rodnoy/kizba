//
//  DiagnosticsModel.swift
//  Kizba
//
//  `@MainActor`, `@Observable` view-model backing `DiagnosticsView`.
//  Reads from the in-memory ``InvocationLog`` and exposes the snapshot
//  to SwiftUI.
//

import Foundation
import Observation

/// Presentation-layer view model for the Diagnostics page.
///
/// The model owns no shell state of its own — every refresh hits the
/// injected ``InvocationLog`` actor and copies the newest-first
/// snapshot into ``recentInvocations`` for the view to render.
@MainActor
@Observable
public final class DiagnosticsModel {

    /// Newest-first list of recent invocations as of the last
    /// ``refresh()`` call. Empty until ``refresh()`` is invoked.
    public private(set) var recentInvocations: [Invocation] = []

    private let invocationLog: InvocationLog

    public init(invocationLog: InvocationLog) {
        self.invocationLog = invocationLog
    }

    /// Reload ``recentInvocations`` from the underlying log.
    public func refresh() async {
        let snapshot = await invocationLog.recent()
        self.recentInvocations = snapshot
    }

    /// Empty the underlying log and the local snapshot.
    public func clear() async {
        await invocationLog.clear()
        self.recentInvocations = []
    }
}
