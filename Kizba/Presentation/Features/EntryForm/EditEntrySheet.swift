//
//  EditEntrySheet.swift
//  Kizba
//
//  Phase G.2 — Full-page sheet hosting `EntryFormModel` in
//  `.edit(originalPath:)` mode. Reachable via:
//    * the `✎` toolbar button on `EntryDetailView`,
//    * the `Entry > Edit Entry…` menu item (⌘E),
//    * any other future affordance binding to
//      `AppState.isEditEntrySheetPresented`.
//
//  Phase B.4 closure — The form body, password field (incl.
//  `SecureField` + reveal toggle), metadata editor and the
//  Generate sub-sheet wiring all live in `EntryFormBody`. This
//  sheet is a thin wrapper that adds the edit-specific header,
//  the loading skeleton, the load-failure surface and the
//  save/cancel footer.
//
//  All visual styling MUST go through `theme.*` tokens; the Phase
//  C.6 `SourceGrepTests` enforce this for every file under
//  `Kizba/Presentation/**` outside `DesignSystem/**`.
//
//  Per `.ai/decisions.md`, the sheet never logs or otherwise
//  surfaces secret material.
//

import SwiftUI

/// Sheet view for editing an existing `pass` entry. Constructed by
/// the hosting view (`EntryDetailView`) which also owns the
/// `isPresented` binding via `AppState.isEditEntrySheetPresented`.
@MainActor
struct EditEntrySheet: View {

    /// Form view-model. `@Bindable` because `EntryFormModel` is
    /// `@Observable`; the form body binds to per-property paths
    /// directly so SwiftUI tracks them without round-tripping
    /// through Combine.
    @Bindable var model: EntryFormModel

    /// Generator threaded into `EntryFormBody` so the Generate
    /// sub-sheet can build a fresh sub-sheet model over the
    /// production collaborator.
    let passwordGenerator: any PasswordGenerating

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    var body: some View {
        Group {
            switch model.state {
            case .loadingExisting:
                loadingChrome
            case .failed(let error) where !hasLoaded:
                loadFailureChrome(error: error)
            default:
                EntryFormBody(
                    model: model,
                    pathFieldEnabled: false,
                    passwordGenerator: passwordGenerator,
                    header: {
                        header
                    },
                    footer: {
                        footerActions
                    }
                )
            }
        }
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
            Text("Edit entry")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)
            Text("Update fields and save.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Loading chrome

    /// Skeleton shown while the initial `pass show` is in flight.
    /// Mirrors the rough shape of the loaded form so the layout
    /// does not jump on transition. Hosted alongside the same
    /// header + footer as the loaded form so the user can still
    /// cancel out of the sheet.
    private var loadingChrome: some View {
        VStack(spacing: theme.spacing.lg) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    LoadingShimmer(width: 80, height: 12)
                    LoadingShimmer(height: 36)

                    LoadingShimmer(width: 80, height: 12)
                    LoadingShimmer(height: 36)

                    LoadingShimmer(width: 80, height: 12)
                    LoadingShimmer(height: 80)

                    LoadingShimmer(width: 80, height: 12)
                    LoadingShimmer(height: 96)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            footerActions
        }
    }

    // MARK: - Load failure chrome

    /// Replaces the form body when the initial `pass show` failed.
    /// There is nothing to edit, so we surface a banner + Cancel
    /// affordance rather than letting the user type into an empty
    /// form.
    private func loadFailureChrome(error: PassError) -> some View {
        VStack(spacing: theme.spacing.lg) {
            header
            BannerView(
                severity: .danger,
                title: "Could not load entry",
                message: loadFailureMessage(for: error)
            )
            Spacer(minLength: 0)
            footerActions
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func loadFailureMessage(for error: PassError) -> String {
        switch error {
        case .decryptionFailed:
            return "The entry could not be decrypted. Check pinentry and your GPG agent, then try again."
        case .sourceNotFound(let path):
            return "The entry \(path) is no longer in the store."
        case .timedOut:
            return "The decryption operation timed out."
        case .cancelled:
            return "The decryption was cancelled."
        default:
            return "An unexpected error prevented loading this entry."
        }
    }

    /// `true` once the model has populated `draft` from a
    /// successful `pass show`. Used to distinguish a load-time
    /// failure (no draft yet — render the failure surface) from a
    /// save-time failure (draft loaded — keep showing the form so
    /// the user can correct the input).
    private var hasLoaded: Bool {
        switch model.state {
        case .saving, .saved:
            return true
        case .editing:
            return true
        case .loadingExisting, .idle:
            return false
        case .failed:
            // Heuristic: a save-time failure means we previously
            // transitioned to `.editing` (and likely the user
            // touched the password). A load-time failure means we
            // went directly `.loadingExisting → .failed`. We
            // cannot observe history from the State alone, so use
            // the draft as a proxy: load-time failure leaves the
            // initial empty draft untouched.
            return !model.draft.password.isEmpty
                || !model.draft.metadata.isEmpty
                || !model.draft.notes.isEmpty
        }
    }

    // MARK: - Footer actions

    /// Footer actions. Save is disabled both while saving and while
    /// the initial load is still in flight — the model's
    /// ``EntryFormModel/canSave`` already covers both via its state
    /// branches.
    private var footerActions: some View {
        HStack(spacing: theme.spacing.md) {
            Spacer()
            Button("Cancel") {
                model.cancel()
                dismiss()
            }
            .buttonStyle(.kizba(.ghost))
            .keyboardShortcut(.cancelAction)

            Button("Save changes") {
                model.save()
            }
            .buttonStyle(.kizba(.primary))
            .disabled(!model.canSave)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - State change key

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
