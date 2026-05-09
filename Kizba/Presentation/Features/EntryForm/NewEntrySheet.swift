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
//  All visual styling MUST go through `theme.*` tokens; the Phase
//  C.6 `SourceGrepTests` enforce this for every file under
//  `Kizba/Presentation/**` outside `DesignSystem/**`.
//
//  Per `.ai/decisions.md`, the sheet never logs or otherwise
//  surfaces secret material. The "Generate password…" affordance is
//  shipped as a disabled placeholder; Phase F.4 will wire it to
//  `GeneratePasswordSheet`.
//

import SwiftUI

/// Sheet view for creating a new `pass` entry. Constructed by the
/// hosting view (`EntryListView`) which also owns the
/// `isPresented` binding via `AppState.isNewEntrySheetPresented`.
@MainActor
struct NewEntrySheet: View {

    /// Form view-model. `@Bindable` because `EntryFormModel` is
    /// `@Observable`; the sheet binds to `path`, `draft.password`,
    /// `draft.metadata`, `draft.notes` directly so SwiftUI tracks
    /// per-property changes without round-tripping through Combine.
    @Bindable var model: EntryFormModel

    /// Generator used to populate the Phase F.4 sub-sheet. Captured
    /// at init time so each sub-sheet presentation builds a fresh
    /// ``GeneratePasswordModel`` over the same collaborator. The
    /// hosting view (`EntryListView`) injects ``AppEnvironment``'s
    /// `passwordGenerator` here.
    let passwordGenerator: any PasswordGenerating

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// Local UI state for the password reveal toggle. Kept here
    /// because reveal/hide is presentation-only — the model never
    /// needs to know whether the user is looking at the value.
    @State private var isPasswordRevealed: Bool = false

    /// Drives the `.sheet(isPresented:)` for the Phase F.4
    /// "Generate password…" sub-sheet. Kept as local view state
    /// (not on `AppState`) because the affordance is scoped to this
    /// sheet's lifetime — it would be meaningless when no
    /// ``EntryFormModel`` is being edited.
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
            header
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    pathSection
                    passwordSection
                    metadataSection
                    notesSection
                    if let banner = collisionBanner {
                        banner
                    }
                }
            }
            footerActions
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

    // MARK: - Form sections

    private var pathSection: some View {
        FormSection("Path") {
            FormFieldRow(
                label: "Path",
                helpText: "e.g. personal/github",
                errorText: model.pathError
            ) {
                FolderPathPicker(
                    path: $model.path,
                    availableFolders: [],
                    placeholder: "folder/name"
                )
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
                    // Editable plain TextField for the cleartext value.
                    // `SecretRevealField` is read-only (used for entry
                    // detail); the create form needs an editable input.
                    //
                    // `EntryFormModel.draft` is `private(set)` so the
                    // model can swap the whole draft on dismissal —
                    // we reach mutable fields via proxy bindings.
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
                        .help("Generate a strong password (Phase F.4)")
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

    // MARK: - Bindings + helpers

    /// Two-way binding into `model.draft.password`. Required because
    /// `EntryFormModel.draft` is `private(set)` (the model owns
    /// draft replacement on dismissal); SwiftUI cannot synthesise
    /// `$model.draft.password` against an inaccessible setter.
    private var passwordBinding: Binding<String> {
        Binding(
            get: { model.draft.password },
            set: { model.draft.password = $0 }
        )
    }

    /// Two-way binding into `model.draft.notes` — same rationale as
    /// `passwordBinding`.
    private var notesBinding: Binding<String> {
        Binding(
            get: { model.draft.notes },
            set: { model.draft.notes = $0 }
        )
    }

    /// Adapter binding that bridges `[MetadataPair]` (domain model)
    /// to `[KeyValueEditor.Pair]` (DS component). The two types are
    /// shape-identical so the mapping is mechanical; doing it here
    /// keeps the editor UI agnostic of the domain type.
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
