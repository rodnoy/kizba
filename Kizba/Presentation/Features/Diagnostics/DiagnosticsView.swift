//
//  DiagnosticsView.swift
//  Kizba
//
//  Minimal SwiftUI Diagnostics page that renders the in-memory
//  ``InvocationLog`` snapshot from a ``DiagnosticsModel``. Phase 8.4
//  scope: keep the surface small; richer presentation (filtering,
//  copy-to-clipboard, export) is deferred.
//
//  This view is **not** wired into `KizbaApp` yet — Phase 8 will mount
//  it from the Settings/Diagnostics scene once the rest of the
//  Diagnostics-driven error UI is in place.
//

import SwiftUI

/// Minimal Diagnostics page. One row per recorded invocation showing
/// timestamp, executable basename, sanitised args, exit code, and the
/// (already-sanitised) stderr excerpt.
public struct DiagnosticsView: View {

    @State private var model: DiagnosticsModel

    public init(model: DiagnosticsModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        List(model.recentInvocations) { invocation in
            row(for: invocation)
        }
        .task { await model.refresh() }
        .toolbar {
            ToolbarItem {
                Button("Refresh") {
                    Task { await model.refresh() }
                }
            }
            ToolbarItem {
                Button("Clear") {
                    Task { await model.clear() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for invocation: Invocation) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(Self.timestampFormatter.string(from: invocation.startedAt))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(Self.basename(of: invocation.executable))
                    .font(.body.monospaced())
                Text("exit=\(invocation.exitCode)")
                    .font(.caption.monospaced())
                    .foregroundStyle(invocation.exitCode == 0 ? Color.secondary : Color.red)
            }
            if !invocation.args.isEmpty {
                Text(invocation.args.joined(separator: " "))
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.secondary)
            }
            if !invocation.stderrExcerpt.isEmpty {
                Text(invocation.stderrExcerpt)
                    .font(.caption)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
