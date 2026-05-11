//
//  NewEntrySheet.swift
//  Kizba
//
//  Phase F.3 — Full-page sheet hosting `EntryFormModel` in
//  `.create` mode. Reachable via:
//    * the `+` toolbar button on `EntryListView`,
//    * the `Entry > New Entry…` menu item (⌘N),
//    * any other future affordance binding to
//      `AppState.isNewEntrySheetPresented`.
//
//  Phase B.4 closure — The form body, password field (incl.
//  `SecureField` + reveal toggle), metadata editor and the
//  Generate sub-sheet wiring all live in `EntryFormBody`. This
//  sheet is a thin wrapper that adds the create-specific header,
//  the collision banner and the save/cancel footer.
//
//  All visual styling MUST go through `theme.*` tokens; the Phase
//  C.6 `SourceGrepTests` enforce this for every file under
//  `Kizba/Presentation/**` outside `DesignSystem/**`.
//
//  Per `.ai/decisions.md`, the sheet never logs or otherwise
//  surfaces secret material.
//

import SwiftUI

/// Sheet view for creating a new `pass` entry. Constructed by the
/// hosting view (`EntryListView`) which also owns the
/// `isPresented` binding via `AppState.isNewEntrySheetPresented`.
@MainActor
struct NewEntrySheet: View {

    /// Form view-model. `@Bindable` because `EntryFormModel` is
    /// `@Observable`; the form body binds to per-property paths
    /// directly so SwiftUI tracks them without round-tripping
    /// through Combine.
    @Bindable var model: EntryFormModel

    /// Generator threaded into `EntryFormBody` so the Generate
    /// sub-sheet can build a fresh sub-sheet model over the
    /// production collaborator. The hosting view (`EntryListView`)
    /// injects ``AppEnvironment``'s `passwordGenerator` here.
    let passwordGenerator: any PasswordGenerating

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        EntryFormBody(
            model: model,
            pathFieldEnabled: true,
            passwordGenerator: passwordGenerator,
            header: {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    header
                    if let banner = collisionBanner {
                        banner
                    }
                }
            },
            footer: {
                footerActions
            }
        )
        .padding(theme.spacing.lg)
        .frame(minWidth: 520, minHeight: 560)
        .background(theme.colors.surface)
        .onChange(of: stateChangeKey) { _, _ in
            if case .saved = model.state {
                dismiss()
            }
        }
        .onDisappear {
            model.handleDismissal()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("New Entry")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)
            Text("Create a new password entry in the store.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Collision banner

    /// Inline warning shown when the most recent save failed with
    /// `entryAlreadyExists`. The "Overwrite" action flips the
    /// model's `forceOverwrite` flag and re-issues `save()`; the
    /// user explicitly opts in (no auto-retry).
    @ViewBuilder
    private var collisionBanner: BannerView? {
        if case .failed(let error) = model.state,
           case .entryAlreadyExists(let path) = error {
            BannerView(
                severity: .warning,
                title: "Entry already exists",
                message: "An entry at \(path) is already in the store.",
                action: BannerView.BannerAction(label: "Overwrite") {
                    model.forceOverwrite = true
                    model.save()
                }
            )
        }
    }

    // MARK: - Footer actions

    private var footerActions: some View {
        HStack(spacing: theme.spacing.md) {
            Spacer()
            Button("Cancel") {
                model.cancel()
                dismiss()
            }
            .buttonStyle(.kizba(.ghost))
            .keyboardShortcut(.cancelAction)

            Button("Save") {
                model.save()
            }
            .buttonStyle(.kizba(.primary))
            .disabled(!model.canSave)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - State change key

    /// Compact, `Equatable` representation of `model.state` used as
    /// the `onChange` value. `EntryFormModel.State` is already
    /// `Equatable`, but using a small string key keeps the sheet's
    /// reactive surface explicit and decouples the dismiss trigger
    /// from any future associated-value churn on `State`.
    private var stateChangeKey: String {
        switch model.state {
        case .idle: return "idle"
        case .loadingExisting: return "loadingExisting"
        case .editing: return "editing"
        case .saving: return "saving"
        case .saved(let path): return "saved:\(path)"
        case .failed(let error): return "failed:\(error)"
        }
    }
}
