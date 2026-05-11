//
//  EntryFormBody.swift
//  Kizba
//
//  Phase B.4 — Shared form body extracted from NewEntrySheet /
//  EditEntrySheet. Hosts Path, Password, Metadata and Notes
//  sections and owns the GeneratePasswordSheet wiring so callers
//  only provide header / footer slots.
//
//  Phase D.3 closure — The password input is rendered via
//  `SecureField` by default with a reveal toggle that mirrors the
//  read-only `SecretRevealField` accessibility contract. The
//  reveal state is presentation-only and never crosses the model.
//

import SwiftUI

/// Shared entry form body used by NewEntrySheet and EditEntrySheet.
///
/// Provides four form sections (Path, Password, Metadata, Notes)
/// and header/footer slots. It also owns the Generate password
/// sub-sheet so the parent sheets do not need to duplicate that
/// wiring.
public struct EntryFormBody<Header: View, Footer: View>: View {

    // Exposed for testability: stored model and the pathField flag.
    internal let model: EntryFormModel
    internal let pathFieldEnabled: Bool

    // Slots captured at init so tests may inspect them.
    internal let headerView: Header
    internal let footerView: Footer

    /// Generator used by the "Generate password…" sub-sheet. Held
    /// as `any PasswordGenerating` so previews and tests may inject
    /// a deterministic stub. The sheet wiring builds a fresh
    /// `GeneratePasswordModel` per presentation over this generator.
    internal let passwordGenerator: any PasswordGenerating

    @Environment(\.theme) private var theme

    // Generate sub-sheet state owned by this body.
    @State private var isGenerateSheetPresented: Bool = false
    @State private var generatePasswordModel: GeneratePasswordModel?

    /// Local UI state for the password reveal toggle. Kept here
    /// because reveal/hide is presentation-only — the model never
    /// needs to know whether the user is looking at the value.
    /// Defaults to masked (`false`) so the password is never
    /// rendered in cleartext until the user explicitly opts in.
    @State private var isPasswordRevealed: Bool = false

    /// Construct a body backed by `model`.
    init(
        model: EntryFormModel,
        pathFieldEnabled: Bool,
        passwordGenerator: any PasswordGenerating = LivePasswordGenerator(),
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.model = model
        self.pathFieldEnabled = pathFieldEnabled
        self.passwordGenerator = passwordGenerator
        self.headerView = header()
        self.footerView = footer()
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            headerView

            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    pathSection
                    passwordSection
                    metadataSection
                    notesSection
                }
            }

            footerView
        }
        .onChange(of: isGenerateSheetPresented) { _, presented in
            if presented {
                // Build a fresh generator model per presentation.
                generatePasswordModel = GeneratePasswordModel(
                    generator: passwordGenerator
                )
            }
        }
        .sheet(isPresented: $isGenerateSheetPresented, onDismiss: {
            generatePasswordModel = nil
        }) {
            if let subModel = generatePasswordModel {
                GeneratePasswordSheet(model: subModel) { newPassword in
                    model.draft.password = newPassword
                }
            }
        }
    }

    // MARK: - Sections

    private var pathSection: some View {
        FormSection("Path") {
            FormFieldRow(
                label: "Path",
                helpText: pathFieldEnabled ? "e.g. personal/github" : "Path is fixed in edit mode — use Move to rename.",
                errorText: model.pathError
            ) {
                FolderPathPicker(
                    path: Binding(get: { model.path }, set: { model.path = $0 }),
                    availableFolders: [],
                    placeholder: "folder/name"
                )
                .disabled(!pathFieldEnabled)
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
                    HStack(spacing: theme.spacing.sm) {
                        // The password input is rendered as either a
                        // `SecureField` (default — characters are
                        // masked and never read aloud by VoiceOver
                        // as they are typed) or a plain `TextField`
                        // when the user has opted into reveal. The
                        // two branches must share the same binding
                        // so toggling does not lose in-flight input.
                        if isPasswordRevealed {
                            TextField(
                                "password",
                                text: Binding(get: { model.draft.password }, set: { model.draft.password = $0 }),
                                prompt: Text("password")
                            )
                            .textFieldStyle(.kizba)
                        } else {
                            SecureField(
                                "password",
                                text: Binding(get: { model.draft.password }, set: { model.draft.password = $0 }),
                                prompt: Text("password")
                            )
                            .textFieldStyle(.kizba)
                        }

                        Button {
                            isPasswordRevealed.toggle()
                        } label: {
                            Image(systemName: isPasswordRevealed ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.kizba(.ghost, size: .compact))
                        .accessibilityLabel(isPasswordRevealed ? "Hide password" : "Reveal password")
                        .accessibilityValue(EntryFormBody<Header, Footer>.passwordRevealAccessibilityValue(isRevealed: isPasswordRevealed))
                        .help(isPasswordRevealed ? "Hide password" : "Reveal password")
                    }

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
            TextEditor(text: Binding(get: { model.draft.notes }, set: { model.draft.notes = $0 }))
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 96)
                .padding(theme.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                        .fill(theme.colors.surfaceSunken)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                        .strokeBorder(theme.colors.divider, lineWidth: 1)
                )
        }
    }

    // MARK: - Bindings

    private var keyValueEditorBinding: Binding<[KeyValueEditor.Pair]> {
        Binding(
            get: {
                model.draft.metadata.map { pair in
                    KeyValueEditor.Pair(id: pair.id, key: pair.key, value: pair.value)
                }
            },
            set: { newPairs in
                model.draft.metadata = newPairs.map { pair in
                    MetadataPair(id: pair.id, key: pair.key, value: pair.value)
                }
            }
        )
    }

    // MARK: - Pure helpers (testable contract)

    /// Accessibility value string describing the current reveal state
    /// of the password field. Mirrors
    /// `SecretRevealField.accessibilityValueText(isRevealed:)` so the
    /// editable and read-only secret affordances announce the same
    /// vocabulary to assistive tech.
    static func passwordRevealAccessibilityValue(isRevealed: Bool) -> String {
        isRevealed ? "Revealed" : "Hidden"
    }
}
