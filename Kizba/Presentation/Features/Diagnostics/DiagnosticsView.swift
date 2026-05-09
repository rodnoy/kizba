//
//  DiagnosticsView.swift
//  Kizba
//
//  Minimal SwiftUI Diagnostics page that renders the in-memory
//  ``InvocationLog`` snapshot from a ``DiagnosticsModel``. Phase 8.4
//  scope: keep the surface small; richer presentation (filtering,
//  copy-to-clipboard, export) is deferred.
//
//  Phase C.4 migrated typography and color literals to design-system
//  tokens; the toolbar buttons remain system-styled (toolbar audit is
//  Phase C.5). When the log is empty, the row list is replaced by a
//  themed `EmptyStateView`.
//

import SwiftUI

/// Minimal Diagnostics page. One row per recorded invocation showing
/// timestamp, executable basename, sanitised args, exit code, and the
/// (already-sanitised) stderr excerpt.
public struct DiagnosticsView: View {

    @State private var model: DiagnosticsModel

    @Environment(\.theme) private var theme

    public init(model: DiagnosticsModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        Group {
            if model.recentInvocations.isEmpty {
                EmptyStateView(
                    iconName: "doc.text.magnifyingglass",
                    title: "No invocations recorded",
                    message: "Run a `pass` command to see entries here."
                )
            } else {
                List(model.recentInvocations) { invocation in
                    row(for: invocation)
                }
            }
        }
        .task { await model.refresh() }
        .toolbar {
            // Phase I.1 — `.help(...)` tooltips parity with the
            // Entry list / detail toolbars. Diagnostics is reachable
            // via ⌘⌥D from anywhere in the main window context;
            // these per-button tooltips describe each affordance on
            // hover. No keyboard shortcut on the toolbar itself
            // because the Diagnostics window has its own focused
            // toolbar context (no risk of collision with main-window
            // bindings).
            ToolbarItem {
                Button("Refresh") {
                    Task { await model.refresh() }
                }
                .help("Refresh invocation log")
            }
            ToolbarItem {
                Button("Clear") {
                    Task { await model.clear() }
                }
                .help("Clear invocation log")
            }
        }
    }

    @ViewBuilder
    private func row(for invocation: Invocation) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                Text(Self.timestampFormatter.string(from: invocation.startedAt))
                    .font(theme.typography.monoSmall)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                Text(Self.basename(of: invocation.executable))
                    .font(theme.typography.mono)
                    .foregroundStyle(theme.colors.onSurface)
                Text("exit=\(invocation.exitCode)")
                    .font(theme.typography.monoSmall)
                    .foregroundStyle(
                        invocation.exitCode == 0
                            ? theme.colors.success
                            : theme.colors.danger
                    )
            }
            if !invocation.args.isEmpty {
                Text(invocation.args.joined(separator: " "))
                    .font(theme.typography.monoSmall)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }
            if !invocation.stderrExcerpt.isEmpty {
                Text(invocation.stderrExcerpt)
                    .font(theme.typography.caption)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }

    private static func basename(of path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
