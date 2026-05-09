//
//  GeneratePasswordSheet.swift
//  Kizba
//
//  Phase F.4 — Sub-sheet hosted by `NewEntrySheet`'s "Generate
//  password…" affordance. Shows a length stepper, an
//  include-symbols toggle, a live preview of the candidate password
//  and Regenerate / Use / Cancel actions.
//
//  The sub-sheet is intentionally decoupled from `EntryFormModel`:
//  it owns a private ``GeneratePasswordModel`` and surfaces the
//  applied password through an `onApply` callback. The caller
//  (`NewEntrySheet`) is responsible for writing the password back
//  into its own draft. This keeps the generator UI reusable and
//  makes the data flow obvious in code review.
//
//  All visual styling MUST go through `theme.*` tokens; the Phase
//  C.6 `SourceGrepTests` enforce this for every file under
//  `Kizba/Presentation/**` outside `DesignSystem/**`.
//

import SwiftUI

/// Sub-sheet view for previewing and applying a generated password.
///
/// Constructed by the hosting view (`NewEntrySheet`), which also
/// owns the `isPresented` binding for the `.sheet(...)` modifier.
@MainActor
struct GeneratePasswordSheet: View {

    /// Generator view-model. `@Bindable` because
    /// ``GeneratePasswordModel`` is `@Observable`; the sheet binds
    /// to ``GeneratePasswordModel/length`` and
    /// ``GeneratePasswordModel/includeSymbols`` directly so SwiftUI
    /// tracks per-property changes without round-tripping through
    /// Combine.
    @Bindable var model: GeneratePasswordModel

    /// Called when the user confirms the preview via "Use this
    /// password". Receives the chosen cleartext value; the caller
    /// is expected to write it into its own draft and dismiss any
    /// state tied to the previous value. Never invoked when the
    /// model is in ``GeneratePasswordModel/State/error(_:)``.
    let onApply: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// Local UI state for the preview reveal toggle. Defaults to
    /// `true`: the user is explicitly reviewing the candidate
    /// password before committing to it, so masking it on first
    /// render would be hostile.
    @State private var isPreviewRevealed: Bool = true

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            header
            previewSection
            controls
            errorSection
            footerActions
        }
        .padding(theme.spacing.lg)
        .frame(minWidth: 380)
        .background(theme.colors.surface)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Generate password")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)
            Text("Preview a strong password before applying it.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Preview section

    /// Renders the previewed password through ``SecretRevealField``
    /// so the visual language matches the rest of the app, plus a
    /// small ghost button to re-roll without changing length /
    /// symbols. When the model is in
    /// ``GeneratePasswordModel/State/error(_:)``, the preview slot
    /// collapses (the message is rendered by ``errorSection``).
    @ViewBuilder
    private var previewSection: some View {
        if let pwd = model.previewPassword {
            HStack(spacing: theme.spacing.sm) {
                SecretRevealField(
                    value: pwd,
                    label: "Preview",
                    isRevealed: $isPreviewRevealed,
                    // No-op copy: the preview is committed via "Use
                    // this password", not via the clipboard. We keep
                    // the field's affordance for visual consistency
                    // and reveal/hide control, but copying the
                    // candidate before applying it would needlessly
                    // expand the secret's blast radius.
                    onCopy: {},
                    copyButtonLabel: "Copy"
                )
                Button {
                    model.regenerate()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.kizba(.ghost, size: .compact))
                .help("Regenerate (\u{2318}R)")
                .keyboardShortcut("r", modifiers: .command)
                .accessibilityLabel("Regenerate password preview")
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                Text("Length")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurface)
                Spacer()
                // Render the current length as a separate Text so it
                // stays visible — `.labelsHidden()` on the Stepper
                // hides its label content (which would otherwise be
                // the value display).
                Text("\(model.length)")
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onSurface)
                    .monospacedDigit()
                // Use a proxy Binding so the regenerate side effect
                // fires on every commit. `.onChange(of:)` against an
                // Observation-tracked property may not fire if the
                // body never reads the property — the proxy makes
                // the write path explicit.
                Stepper(
                    "Length",
                    value: Binding(
                        get: { model.length },
                        set: { model.length = $0; model.regenerate() }
                    ),
                    in: GeneratePasswordModel.lengthBounds,
                    step: 1
                )
                .labelsHidden()
            }
            // Same proxy-Binding pattern as the Stepper above —
            // ensures `regenerate()` runs on every toggle commit.
            Toggle(isOn: Binding(
                get: { model.includeSymbols },
                set: { model.includeSymbols = $0; model.regenerate() }
            )) {
                Text("Include symbols")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurface)
            }
            .toggleStyle(.switch)
        }
    }

    // MARK: - Error section

    /// Surfaces ``GeneratePasswordModel/State/error(_:)`` as a
    /// danger banner. The error message is already user-facing
    /// (constructed by the model), so the banner just frames it.
    @ViewBuilder
    private var errorSection: some View {
        if case .error(let msg) = model.state {
            BannerView(
                severity: .danger,
                title: "Generation failed",
                message: msg
            )
        } else {
            EmptyView()
        }
    }

    // MARK: - Footer actions

    private var footerActions: some View {
        HStack(spacing: theme.spacing.md) {
            Spacer()
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.kizba(.ghost))
            .keyboardShortcut(.cancelAction)

            Button("Use this password") {
                if let pwd = model.previewPassword {
                    onApply(pwd)
                    dismiss()
                }
            }
            .buttonStyle(.kizba(.primary))
            .disabled(model.previewPassword == nil)
            .keyboardShortcut(.defaultAction)
        }
    }
}
