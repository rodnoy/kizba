//
//  ImportPreviewSheet.swift
//  Kizba
//
//  Sheet shown after parsing an import file but BEFORE any
//  `pass insert` runs. Lets the user choose a conflict resolution
//  strategy and confirm the import. The sheet does not own the
//  import flow — the calling `DataTab` owns the state machine and
//  drives the actual writes after `onConfirm` fires.
//

import SwiftUI

/// Wrapper that gives ``ImportPreview`` SwiftUI-stable identity so
/// it can be presented via `.sheet(item:)`. A fresh `IdentifiedImportPreview`
/// is built every time the parser produces a new preview, so the
/// associated UUID always changes — exactly what `.sheet(item:)`
/// needs to re-present after dismissal.
public struct IdentifiedImportPreview: Identifiable, Equatable {
    public let id = UUID()
    public let preview: ImportPreview

    public init(_ preview: ImportPreview) {
        self.preview = preview
    }
}

struct ImportPreviewSheet: View {

    let preview: ImportPreview
    let onConfirm: (ImportConflictStrategy) -> Void
    let onCancel: () -> Void

    @State private var strategy: ImportConflictStrategy = .skip
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Text("Import preview")
                .font(theme.typography.title)

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("\(preview.totalCount) entries to import")
                    .font(theme.typography.body)
                Text("\(preview.newCount) new")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.success)
                if preview.conflictCount > 0 {
                    Text("\(preview.conflictCount) conflicts with existing paths")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.warning)
                }
            }

            if preview.conflictCount > 0 {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Conflict strategy")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                    Picker("Conflict strategy", selection: $strategy) {
                        Text("Skip").tag(ImportConflictStrategy.skip)
                        Text("Overwrite").tag(ImportConflictStrategy.overwrite)
                        Text("Rename (-2, -3, …)").tag(ImportConflictStrategy.rename)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }

            if !preview.parseWarnings.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("Warnings")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.warning)
                    ForEach(Array(preview.parseWarnings.prefix(10).enumerated()), id: \.offset) { _, warning in
                        Text("• \(warning)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                    }
                    if preview.parseWarnings.count > 10 {
                        Text("… and \(preview.parseWarnings.count - 10) more")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                    }
                }
                .padding(theme.spacing.md)
                .background(theme.colors.warningMuted)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Import \(effectiveCount) entries") {
                    onConfirm(strategy)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(effectiveCount == 0)
            }
        }
        .padding(theme.spacing.xl)
        .frame(minWidth: 480)
    }

    /// Count that will actually be applied under the current
    /// strategy. `.skip` drops conflicts; `.overwrite` / `.rename`
    /// keep them.
    private var effectiveCount: Int {
        switch strategy {
        case .skip:
            return preview.newCount
        case .overwrite, .rename:
            return preview.totalCount
        }
    }
}
