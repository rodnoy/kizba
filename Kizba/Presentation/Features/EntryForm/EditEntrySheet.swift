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
//  This sheet is intentionally a copy-and-adapt of `NewEntrySheet`
//  rather than a thin wrapper around a shared body view: the two
//  sheets WILL diverge over time (edit has a loading skeleton and
//  no collision banner; create has a collision banner and no
//  loading state). Extraction of a shared `EntryFormBody` is left
//  for a future step if the duplication becomes painful.
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
    /// `@Observable`; the sheet binds to `path`, `draft.password`,
    /// `draft.metadata`, `draft.notes` directly so SwiftUI tracks
    /// per-property changes without round-tripping through Combine.
    @Bindable var model: EntryFormModel

    /// Generator used to populate the "Generate password…" sub-sheet.
    /// Captured at init time so each sub-sheet presentation builds a
    /// fresh ``GeneratePasswordModel`` over the same collaborator.
    let passwordGenerator: any PasswordGenerating

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// Local UI state for the password reveal toggle. Kept here
    /// because reveal/hide is presentation-only — the model never
    /// needs to know whether the user is looking at the value.
    @State private var isPasswordRevealed: Bool = false

    /// Drives the `.sheet(isPresented:)` for the "Generate password…"
    /// sub-sheet. Kept as local view state (not on `AppState`)
    /// because the affordance is scoped to this sheet's lifetime.
    @State private var isGenerateSheetPresented: Bool = false

    /// Backing storage for the sub-sheet's view-model. Held as
    /// `@State` (rather than constructed inline inside the
    /// `.sheet` content closure) so that re-evaluations of this
    /// view's body — which re-run the `@ViewBuilder` content
    /// closure — do NOT recreate the model and clobber any
    /// in-flight user input on `length` / `includeSymbols`. The
    /// model is lazily instantiated in
    /// `.onChange(of: isGenerateSheetPresented)` and released in
    /// the `.sheet`'s `onDismiss` so the cleartext preview is torn
    /// down as soon as the sub-sheet closes.
    @State private var generatePasswordModel: GeneratePasswordModel?

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            EntryFormBody(model: model, pathFieldEnabled: false, header: {
                header
            }, footer: {
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
            })
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
        .onChange(of: isGenerateSheetPresented) { _, presented in
            // Lazily build the sub-sheet's model exactly once per
            // presentation. Constructing it inside the `.sheet`
            // content closure would recreate it on every parent
            // body re-evaluation, overwriting any user input via
            // the Stepper / Toggle on the next render.
            if presented {
                generatePasswordModel = GeneratePasswordModel(
                    generator: passwordGenerator
                )
            }
        }
        .sheet(
            isPresented: $isGenerateSheetPresented,
            onDismiss: {
                // Release the cleartext preview as soon as the
                // sub-sheet is torn down (preserves the original
                // intent of building a fresh model per presentation).
                generatePasswordModel = nil
            }
        ) {
            // The `@State`-held model is the single instance the
            // sub-sheet observes for the duration of this
            // presentation. The `onApply` callback is the only way
            // data crosses back into the parent draft.
            if let subModel = generatePasswordModel {
                GeneratePasswordSheet(
                    model: subModel,
                    onApply: { newPassword in
                        model.draft.password = newPassword
                    }
                )
            }
        }
    }

    // MARK: - Content router

    /// Routes between the loading skeleton, the unrecoverable load-
    /// failure surface, and the editable form body. Save-time
    /// failures still render the form (the Save button is disabled
    /// while `state == .saving`); only load-time failures swap the
    /// body wholesale because there is nothing to edit.
    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loadingExisting:
            loadingBody
        case .failed(let error) where !hasLoaded:
            // Initial-load failure — the user cannot edit something
            // we never decrypted. Render a banner with a Close
            // affordance instead of the form.
            loadFailureBody(error: error)
        default:
            formBody
        }
    }

    /// `true` once the model has populated ``draft`` from a
    /// successful `pass show`. Used to distinguish a load-time
    /// failure (no draft yet — render the failure surface) from a
    /// save-time failure (draft loaded — keep showing the form so
    /// the user can correct the input). Approximated by checking
    /// `state` history via the password having been populated:
    /// `SecretDraft(from:)` always sets a non-empty password (real
    /// pass entries always have one), and the user has not yet
    /// touched the field at the moment of the first load failure.
    /// For the rare case where the entry's password is empty AND
    /// the user has typed nothing, both paths render an identical
    /// empty form — acceptable. Save-time failures always have a
    /// populated draft because the user typed it.
    private var hasLoaded: Bool {
        // Once the state has been `.editing` we must have either
        // started in `.create` (not this sheet) or transitioned out
        // of `.loadingExisting` successfully. The model never goes
        // `.editing → .loadingExisting`, so reaching `.failed` from
        // `.editing` (a save failure) implies hasLoaded.
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

    // MARK: - Loading skeleton

    /// Skeleton shown while the initial `pass show` is in flight.
    /// Mirrors the rough shape of the loaded form so the layout
    /// does not jump on transition.
    private var loadingBody: some View {
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
    }

    // MARK: - Load failure

    /// Replaces the form body when the initial `pass show` failed.
    /// There is nothing to edit, so we surface a banner + Close
    /// button rather than letting the user type into an empty form.
    private func loadFailureBody(error: PassError) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            BannerView(
                severity: .danger,
                title: "Could not load entry",
                message: loadFailureMessage(for: error)
            )
            Spacer(minLength: 0)
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

    // MARK: - Form body

    private var formBody: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                pathSection
                passwordSection
                metadataSection
                notesSection
            }
        }
    }

    private var pathSection: some View {
        FormSection("Path") {
            FormFieldRow(
                label: "Path",
                helpText: model.canEditPath
                    ? "e.g. personal/github"
                    : "Path is fixed in edit mode — use Move to rename.",
                errorText: model.pathError
            ) {
                FolderPathPicker(
                    path: $model.path,
                    availableFolders: [],
                    placeholder: "folder/name"
                )
                .disabled(!model.canEditPath)
            }
        }
    }

    private var passwordSection: some View {
        FormSection("Password") {
            FormFieldRow(
                label: "Password",
                helpText: nil,
                errorText: model.passwordError
            ) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    TextField(
                        "password",
                        text: passwordBinding,
                        prompt: Text("password")
                    )
                    .textFieldStyle(.kizba)

                    HStack(spacing: theme.spacing.sm) {
                        Spacer()
                        Button("Generate password…") {
                            isGenerateSheetPresented = true
                        }
                        .buttonStyle(.kizba(.ghost, size: .compact))
                        .help("Generate a strong password")
                    }
                }
            }
        }
    }

    private var metadataSection: some View {
        FormSection("Metadata") {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                KeyValueEditor(pairs: keyValueEditorBinding)
                if let metadataError = model.metadataError {
                    Text(metadataError)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var notesSection: some View {
        FormSection("Notes") {
            TextEditor(text: notesBinding)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 96)
                .padding(theme.spacing.sm)
                .background(
                    RoundedRectangle(
                        cornerRadius: theme.radius.sm,
                        style: .continuous
                    )
                    .fill(theme.colors.surfaceSunken)
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: theme.radius.sm,
                        style: .continuous
                    )
                    .strokeBorder(theme.colors.divider, lineWidth: 1)
                )
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

    // MARK: - Bindings + helpers

    private var passwordBinding: Binding<String> {
        Binding(
            get: { model.draft.password },
            set: { model.draft.password = $0 }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { model.draft.notes },
            set: { model.draft.notes = $0 }
        )
    }

    private var keyValueEditorBinding: Binding<[KeyValueEditor.Pair]> {
        Binding(
            get: {
                model.draft.metadata.map { pair in
                    KeyValueEditor.Pair(
                        id: pair.id,
                        key: pair.key,
                        value: pair.value
                    )
                }
            },
            set: { newPairs in
                model.draft.metadata = newPairs.map { pair in
                    MetadataPair(
                        id: pair.id,
                        key: pair.key,
                        value: pair.value
                    )
                }
            }
        )
    }

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
