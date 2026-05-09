//
//  MoveEntrySheet.swift
//  Kizba
//
//  Phase G.4 — compact sheet hosting `MoveEntryModel`. Reachable via
//  the ↔ toolbar button on `EntryListView` and the
//  `Entry > Move Entry…` menu item (⌘⇧M).
//
//  Layout: header (title + "currently at" subtitle), single
//  `FolderPathPicker` for the new path, optional collision
//  ``BannerView/Severity/warning`` with a "Replace" action, optional
//  generic-error ``BannerView/Severity/danger`` banner, footer
//  Cancel / Move actions. Auto-dismisses on `.saved`.
//
//  Visual styling MUST go through `theme.*` tokens; the Phase C.6
//  `SourceGrepTests` enforce this for every file under
//  `Kizba/Presentation/**` outside `DesignSystem/**`.
//

import SwiftUI

/// Sheet view for moving / renaming the currently-selected entry.
@MainActor
struct MoveEntrySheet: View {

    /// View-model. `@Bindable` because ``MoveEntryModel`` is
    /// `@Observable`; the sheet binds to its `newPath` directly so
    /// SwiftUI tracks per-property changes without round-tripping
    /// through Combine.
    @Bindable var model: MoveEntryModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            header
            pathField
            collisionBanner
            errorBanner
            footerActions
        }
        .padding(theme.spacing.lg)
        .frame(minWidth: 420)
        .background(theme.colors.surface)
        // Auto-dismiss on success. The model lands in `.saved(_)`
        // once `pass.move(...)` returns; SwiftUI runs `.onChange`
        // synchronously on the MainActor, so the dismiss happens
        // on the same turn-of-the-runloop as the state mutation.
        .onChange(of: stateID) { _, _ in
            if case .saved = model.state { dismiss() }
        }
        .onDisappear {
            model.handleDismissal()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Move entry")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)
            Text("Currently at: \(model.originalEntry.path)")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Path field

    private var pathField: some View {
        FormFieldRow(
            label: "New path",
            helpText: "e.g. personal/github",
            errorText: model.pathError
        ) {
            FolderPathPicker(
                path: $model.newPath,
                availableFolders: [],
                placeholder: "folder/name"
            )
            .disabled(isSaving)
        }
    }

    // MARK: - Collision banner

    /// Inline `.warning` banner shown when the model is in
    /// ``MoveEntryModel/State/failed(_:)`` with an
    /// ``PassError/entryAlreadyExists(path:)`` (the only inline-
    /// recoverable error from `move`). The "Replace" action flips
    /// `forceMove = true` and re-invokes ``MoveEntryModel/save()``.
    @ViewBuilder
    private var collisionBanner: some View {
        if case .failed(let error) = model.state,
           case .entryAlreadyExists(let path) = error {
            BannerView(
                severity: .warning,
                title: "An entry already exists at \(path).",
                message: "Replace the existing entry with this one?",
                action: BannerView.BannerAction(label: "Replace") {
                    model.forceMove = true
                    model.save()
                }
            )
        } else {
            EmptyView()
        }
    }

    // MARK: - Generic error banner

    /// Inline `.danger` banner shown when the model is in
    /// ``MoveEntryModel/State/failed(_:)`` with a non-recoverable
    /// error (anything other than ``PassError/entryAlreadyExists``,
    /// which the collision banner above handles). The sheet stays
    /// open so the user can retry or cancel.
    @ViewBuilder
    private var errorBanner: some View {
        if case .failed(let error) = model.state, !error.inlineRecoverable {
            BannerView(
                severity: .danger,
                title: "Could not move entry",
                message: errorMessage(for: error)
            )
        } else {
            EmptyView()
        }
    }

    // MARK: - Footer

    private var footerActions: some View {
        HStack(spacing: theme.spacing.md) {
            Spacer()
            Button("Cancel") {
                model.cancel()
                dismiss()
            }
            .buttonStyle(.kizba(.ghost))
            .keyboardShortcut(.cancelAction)
            .disabled(isSaving)

            Button("Move") {
                model.save()
            }
            .buttonStyle(.kizba(.primary))
            .disabled(!model.canSave)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Derived

    /// Whether the model is currently mid-save. Disables the path
    /// picker + footer actions to prevent double-clicks racing the
    /// in-flight CLI call.
    private var isSaving: Bool {
        if case .saving = model.state { return true }
        return false
    }

    /// Stable identifier for the discrete state, suitable for
    /// `.onChange`. We use a derived integer rather than the State
    /// enum directly so the modifier compiles even if `State` ever
    /// gains a non-`Equatable` payload.
    private var stateID: Int {
        switch model.state {
        case .idle:    return 0
        case .saving:  return 1
        case .saved:   return 2
        case .failed:  return 3
        }
    }

    /// Map a ``PassError`` to a brief user-facing message. Mirrors
    /// the abbreviated rendering used elsewhere in the app for
    /// inline form banners — full diagnostics belong in the
    /// Diagnostics window, not in a sub-sheet.
    private func errorMessage(for error: PassError) -> String {
        switch error {
        case .sourceNotFound(let path):
            return "Entry \(path) is no longer in the password store."
        case .recipientNotFound:
            return "GPG could not resolve a recipient from the store's `.gpg-id`."
        case .timedOut:
            return "The operation took too long and was aborted."
        case .cancelled:
            return "The operation was cancelled."
        default:
            return "An unexpected error occurred. See the Diagnostics window for details."
        }
    }
}
