//
//  EntryDetailView.swift
//  Kizba
//
//  Detail (right) column of the root `NavigationSplitView`. Renders
//  the four discrete `EntryDetailModel.State` phases — idle, loading,
//  loaded, failed — and exposes the per-field copy buttons.
//
//  The view never persists or composes the password: the cleartext
//  string lives only inside the model's `State.loaded(PassSecret)`
//  case and reaches the UI exclusively through inline reads here.
//
//  Phase C.4 migration:
//  - Idle state → `EmptyStateView` (lock-shield icon).
//  - Loading state → stacked `LoadingShimmer` placeholders shaped like
//    the eventual loaded layout.
//  - Loaded state → `SecretRevealField` for the password row;
//    metadata key/value rows use `theme.typography.monoSmall` with
//    ghost-style Copy buttons; notes block wrapped in `KizbaCard`.
//  - Failed state → `BannerView` / `EmptyStateView` per
//    `ErrorPresentation` case (mapping is unchanged from MVP1; only
//    the rendering layer swapped).
//

import SwiftUI

/// Detail column of `RootSplitView`.
///
/// Owns its `EntryDetailModel` via `@State`. Reacts to
/// `AppState.selectedEntryID` changes through `.onChange`, forwarding
/// every change to the model so it can cancel any in-flight load and
/// schedule the next one.
@MainActor
struct EntryDetailView: View {

    @Bindable var state: AppState

    @State private var model: EntryDetailModel
    @State private var favoritesModel: FavoritesModel

    /// Sheet-bound edit model held in `@State` so it survives parent
    /// re-renders. Constructed by the matching `.onChange(of:
    /// isPresented)` handler exactly once per presentation and
    /// released in the sheet's `onDismiss`. Holding the model in a
    /// view-local `@State` (rather than constructing it inside the
    /// `.sheet { ... }` ViewBuilder closure) prevents a fresh
    /// `EntryFormModel` from being spawned on every parent body
    /// re-render — which previously re-spawned `loadExistingSecret`
    /// infinitely (the "blinking" edit-sheet bug) and discarded the
    /// in-flight `.editing → .saved` transition because each new
    /// model started over in `.loadingExisting`.
    @State private var editFormModel: EntryFormModel?

    /// Sheet-bound regenerate model — same rationale as
    /// ``editFormModel`` above.
    @State private var regenerateModel: RegenerateInPlaceModel?

    private let environment: AppEnvironment

    @Environment(\.theme) private var theme

    init(environment: AppEnvironment, state: AppState) {
        self.state = state
        self.environment = environment
        self._model = State(
            initialValue: EntryDetailModel(environment: environment, state: state)
        )
        self._favoritesModel = State(initialValue: FavoritesModel(store: environment.favoritesStore))
    }

    var body: some View {
        Group {
            switch model.state {
            case .idle:
                EmptyStateView(
                    iconName: "lock.shield",
                    title: "Select an entry",
                    message: "Pick an entry from the list to view details."
                )
            case .loading:
                LoadingPlaceholder()
            case .loaded(let secret):
                // Intercept reveal attempts through a proxy binding that
                // delegates the true->reveal transition to
                // `model.requestReveal()` so biometric gating can happen
                // at the model layer without changing `SecretRevealField`.
                let revealBinding = Binding<Bool>(
                    get: { model.isPasswordRevealed },
                    set: { newValue in
                        if newValue {
                            Task { await model.requestReveal() }
                        } else {
                            model.isPasswordRevealed = false
                        }
                    }
                )

                LoadedSecretView(
                    secret: secret,
                    isRevealed: revealBinding,
                    onCopyPassword: { @Sendable in Task { await model.copyPassword() } },
                    // Per-field copy callbacks route through the
                    // model's typed copy methods so each post yields
                    // a semantic confirmation toast (`"Password
                    // copied"`, `"\"<key>\" copied"`, `"Notes
                    // copied"`) without the view ever assembling
                    // toast text. The model owns BOTH the clipboard
                    // write AND the toast; the view only knows
                    // which field was tapped.
                    onCopyMetadataKey: { key in
                        Task { await model.copyMetadata(forKey: key) }
                    },
                    onCopyNotes: {
                        Task { await model.copyNotes() }
                    },
                    biometricAuthenticator: nil,
                    gateEnabled: false
                )
            case .failed(let error):
                FailedView(error: error, environment: environment)
            }
        }
        .navigationTitle(state.router.selectedEntryID ?? "Detail")
        .toolbar {
            // Phase G.2 — `✎` Edit Entry. Enabled only when an entry
            // is selected AND the detail model has loaded its body
            // (no point opening an editor for an entry we couldn't
            // decrypt). The button toggles `AppState.isEditEntry…`
            // which the sheet host below consumes.
            ToolbarItem {
                Button {
                    state.router.isEditEntrySheetPresented = true
                } label: {
                    Label("Edit Entry", systemImage: "pencil")
                }
                // Phase G.6 — disable when no editable selection OR
                // when any write op is in flight (concurrent-write
                // lockout).
                .disabled(!canEditCurrentEntry || state.anyWriteInFlight)
                .help("Edit Entry (⌘E)")
                .accessibilityHint("Keyboard shortcut: ⌘E")
            }
            // Phase G.3 — 🎲 Regenerate Password. Same enable rule
            // as Edit (selection + loaded body). Toggles
            // `AppState.isRegenerateSheetPresented` which the sheet
            // host below consumes.
            ToolbarItem {
                Button {
                    guard let path = state.router.selectedEntryID else { return }
                    Task { await favoritesModel.toggle(path) }
                } label: {
                    Label(
                        "Toggle Favorite",
                        systemImage: {
                            guard let path = state.router.selectedEntryID else { return "star" }
                            return favoritesModel.favorites.contains(path) ? "star.fill" : "star"
                        }()
                    )
                }
                .disabled(state.router.selectedEntryID == nil)
                .help("Toggle Favorite (⌘D)")
            }
            ToolbarItem {
                Button {
                    state.router.isRegenerateInPlaceSheetPresented = true
                } label: {
                    Label("Regenerate Password", systemImage: "dice")
                }
                // Phase G.6 — disable when no editable selection OR
                // when any write op is in flight (concurrent-write
                // lockout).
                .disabled(!canEditCurrentEntry || state.anyWriteInFlight)
                .help("Regenerate Password (⌘⌥G)")
                .accessibilityHint("Keyboard shortcut: ⌘⌥G")
            }
        }
        // Build the regenerate model BEFORE presenting the sheet so
        // the `.sheet { ... }` ViewBuilder closure can read it from
        // `@State`. See ``regenerateModel`` for the rationale.
        .onChange(of: state.router.isRegenerateInPlaceSheetPresented) { _, presented in
            if presented, let path = state.router.selectedEntryID {
                regenerateModel = makeRegenerateInPlaceModel(path: path)
            }
        }
        .sheet(
            isPresented: $state.router.isRegenerateInPlaceSheetPresented,
            onDismiss: { regenerateModel = nil }
        ) {
            if let model = regenerateModel {
                InPlaceGenerateSheet(model: model)
            } else {
                // Defensive fallback — should be unreachable because
                // the toolbar/menu disable themselves without a
                // selection. Render a minimal placeholder so the
                // sheet is dismissable instead of empty.
                Text("No entry selected.")
                    .padding()
            }
        }
        // Same `@State`-held pattern for the Edit sheet. Without it,
        // every parent re-render would spawn a fresh `EntryFormModel`
        // whose `loadExistingSecret` would race the previous one's,
        // producing the "blinking" load behaviour and never observing
        // the prior model's `.saved` transition (so the sheet would
        // never auto-dismiss after Save).
        .onChange(of: state.router.isEditEntrySheetPresented) { _, presented in
            if presented, let path = state.router.selectedEntryID {
                editFormModel = makeEditEntryFormModel(originalPath: path)
            }
        }
        .sheet(
            isPresented: $state.router.isEditEntrySheetPresented,
            onDismiss: { editFormModel = nil }
        ) {
            if let model = editFormModel {
                EditEntrySheet(
                    model: model,
                    passwordGenerator: environment.passwordGenerator
                )
            } else {
                // Defensive fallback — should be unreachable because
                // the toolbar/menu disable themselves without a
                // selection. Render a minimal placeholder so the
                // sheet is dismissable instead of empty.
                Text("No entry selected.")
                    .padding()
            }
        }
        .onChange(of: state.router.selectedEntryID, initial: true) { _, newValue in
            model.handleSelectionChange(newValue)
        }
        // Phase H.1 — subscribe the detail model to `pass.changes` so
        // a `.updated`/`.removed`/`.moved` event targeting the
        // currently-displayed entry refreshes / clears / re-fetches
        // the body without waiting for a manual ⌘R or selection
        // change. SwiftUI cancels the surrounding task on disappear
        // and `EntryDetailModel.observeChanges()` honours that
        // cancellation by exiting its `for await` loop cleanly.
        .task {
            await favoritesModel.load()
            await model.observeChanges()
        }
    }

    /// Whether the toolbar `✎` button is enabled for the current
    /// selection. Requires both a non-nil selection and a
    /// `.loaded(_)` detail model — opening an editor for an entry
    /// we never decrypted would let the user overwrite real data
    /// with whatever happened to be in an empty form.
    private var canEditCurrentEntry: Bool {
        guard state.router.selectedEntryID != nil else { return false }
        if case .loaded = model.state { return true }
        return false
    }

    /// Build a fresh `EntryFormModel` in `.edit(originalPath:)` mode
    /// for each presentation of the sheet.
    private func makeEditEntryFormModel(originalPath: String) -> EntryFormModel {
        EntryFormModel(
            mode: .edit(originalPath: originalPath),
            passManager: environment.passManager,
            toastCenter: state.toastCenter,
            appState: state
        )
    }

    /// Build a fresh `RegenerateInPlaceModel` for each presentation
    /// of the in-place generate sheet (Phase G.3). The model captures
    /// `actionHistory` and `toastCenter` from `AppState` so the
    /// success toast's Undo action wires through the same in-session
    /// undo coordinator the rest of Phase G consumes.
    private func makeRegenerateInPlaceModel(path: String) -> RegenerateInPlaceModel {
        RegenerateInPlaceModel(
            entry: PassEntry(path: path),
            passManager: environment.passManager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
    }
}

// MARK: - Loading placeholder

/// Skeleton layout for the loading phase. Mirrors the shape of the
/// loaded view (a wide password row, then a few shorter metadata rows,
/// then a notes block) so the transition into `.loaded` does not jump.
private struct LoadingPlaceholder: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                LoadingShimmer(width: 80, height: 12)
                LoadingShimmer(height: 36)

                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    LoadingShimmer(width: 60, height: 12)
                    LoadingShimmer(width: 240, height: 16)
                    LoadingShimmer(width: 200, height: 16)
                }

                LoadingShimmer(height: 80)
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Loaded state

private struct LoadedSecretView: View {
    let secret: PassSecret
    @Binding var isRevealed: Bool
    let onCopyPassword: @MainActor @Sendable () -> Void
    /// Tapping the per-row Copy button forwards the metadata key
    /// (NOT the value) to the model so the model owns both the
    /// clipboard write and the confirmation toast. Routing by key
    /// keeps the toast title semantic (`"\"<key>\" copied"`) without
    /// the view ever composing toast text.
    let onCopyMetadataKey: @MainActor (String) -> Void
    /// Tapping the Notes Copy button drives the model's
    /// ``EntryDetailModel/copyNotes()`` so the toast can be labelled
    /// `"Notes copied"`.
    let onCopyNotes: @MainActor () -> Void
    let biometricAuthenticator: (any BiometricAuthenticating)?
    let gateEnabled: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                SecretRevealField(
                    value: secret.password,
                    label: "Password",
                    isRevealed: $isRevealed,
                    onCopy: onCopyPassword,
                    biometricAuthenticator: biometricAuthenticator,
                    gateEnabled: gateEnabled
                )
                .accessibilityIdentifier("password-reveal-field")

                if !secret.metadata.fields.isEmpty {
                    metadataSection
                }

                if let notes = secret.metadata.notes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding(theme.spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Metadata")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                ForEach(Array(secret.metadata.fields.enumerated()), id: \.offset) { index, field in
                    HStack(spacing: theme.spacing.sm) {
                        Text("\(field.key):")
                            .font(theme.typography.monoSmall)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Text(field.value)
                            .font(theme.typography.monoSmall)
                            .foregroundStyle(theme.colors.onSurface)
                            .textSelection(.enabled)
                        Spacer()
                        Button("Copy") { onCopyMetadataKey(field.key) }
                            .buttonStyle(.kizba(.ghost, size: .compact))
                            .accessibilityIdentifier("copy-meta-\(index)-button")
                    }
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.sm) {
                Text("Notes")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                Spacer()
                Button("Copy") { onCopyNotes() }
                    .buttonStyle(.kizba(.ghost, size: .compact))
                    .accessibilityIdentifier("copy-notes-button")
            }

            KizbaCard {
                Text(notes)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurface)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Failed state

private struct FailedView: View {
    let error: PassError
    let environment: AppEnvironment

    @State private var showingDiagnostics = false
    @State private var diagnosticsModel: DiagnosticsModel? = nil

    @Environment(\.theme) private var theme

    var body: some View {
        let presentation = ErrorPresentation.present(for: error)

        return Group {
            switch presentation {
            case .emptyState(let nudge):
                EmptyStateView(
                    iconName: emptyStateIcon(for: error),
                    title: nudge.title,
                    message: "Configure the missing tool in Settings to continue."
                ) {
                    // `SettingsLink` (macOS 14+) opens the `Settings { ... }`
                    // scene declared in `KizbaApp` without resorting to a
                    // stringly-typed `NSApp.sendAction` selector.
                    SettingsLink {
                        Text(nudge.actionTitle)
                    }
                    .buttonStyle(.kizba(.primary))
                }

            case .banner(let message, let helpURL):
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    BannerView(
                        severity: .warning,
                        title: "Pinentry not configured",
                        message: message
                    )
                    if let url = helpURL {
                        Link("Help", destination: url)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.accent)
                    }
                }
                .padding(theme.spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            case .inlineWithDiagnostics(let message), .toastWithDiagnostics(let message):
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    BannerView(
                        severity: .danger,
                        title: "Could not decrypt",
                        message: message,
                        action: BannerView.BannerAction(label: "View details") {
                            // Reuse the SHARED `InvocationLog` carried by
                            // `AppEnvironment.live()` so the Diagnostics sheet
                            // renders the actual recorded invocations. In live
                            // wiring `invocationLog` is always populated;
                            // preview/test wirings do not present this sheet.
                            diagnosticsModel = DiagnosticsModel(
                                invocationLog: environment.invocationLog!
                            )
                            showingDiagnostics = true
                        }
                    )
                }
                .padding(theme.spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            case .onboarding(let message):
                EmptyStateView(
                    iconName: "folder.badge.questionmark",
                    title: "Password store not found",
                    message: message
                ) {
                    SettingsLink {
                        Text("Configure store path")
                    }
                    .buttonStyle(.kizba(.primary))
                }

            case .silent:
                EmptyView()
            }
        }
        .sheet(isPresented: $showingDiagnostics) {
            if let model = diagnosticsModel {
                DiagnosticsView(model: model)
                    .task {
                        await model.refresh()
                    }
            } else {
                Text("Loading…")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }
        }
    }

    /// Icon for the `.emptyState` presentation. `binaryNotFound` is the
    /// only PassError that maps here today; pick a tools icon. Any
    /// future addition falls through to a neutral question-mark folder.
    private func emptyStateIcon(for error: PassError) -> String {
        switch error {
        case .binaryNotFound:
            return "wrench.and.screwdriver"
        default:
            return "folder.badge.questionmark"
        }
    }
}
