//
//  EntryFormBody.swift
//  Kizba
//
//  Phase B.4 — Shared form body extracted from NewEntrySheet /
//  EditEntrySheet. Hosts Path, Password, Metadata and Notes
//  sections and owns the GeneratePasswordSheet wiring so callers
//  only provide header / footer slots.
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

    @Environment(\.theme) private var theme

    // Generate sub-sheet state owned by this body.
    @State private var isGenerateSheetPresented: Bool = false
    @State private var generatePasswordModel: GeneratePasswordModel?

    /// Construct a body backed by `model`.
    public init(
        model: EntryFormModel,
        pathFieldEnabled: Bool,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.model = model
        self.pathFieldEnabled = pathFieldEnabled
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
                    generator: LivePasswordGenerator()
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
                    TextField(
                        "password",
                        text: Binding(get: { model.draft.password }, set: { model.draft.password = $0 }),
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
}
