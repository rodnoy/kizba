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
    private let environment: AppEnvironment

    @Environment(\.theme) private var theme

    init(environment: AppEnvironment, state: AppState) {
        self.state = state
        self.environment = environment
        self._model = State(
            initialValue: EntryDetailModel(environment: environment, state: state)
        )
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
                LoadedSecretView(
                    secret: secret,
                    isRevealed: $model.isPasswordRevealed,
                    onCopyPassword: { @Sendable in Task { await model.copyPassword() } },
                    onCopyField: { value in Task { await model.copy(value) } }
                )
            case .failed(let error):
                FailedView(error: error, environment: environment)
            }
        }
        .navigationTitle(state.selectedEntryID ?? "Detail")
        .onChange(of: state.selectedEntryID, initial: true) { _, newValue in
            model.handleSelectionChange(newValue)
        }
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
    let onCopyField: @MainActor (String) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                SecretRevealField(
                    value: secret.password,
                    label: "Password",
                    isRevealed: $isRevealed,
                    onCopy: onCopyPassword
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
                        Button("Copy") { onCopyField(field.value) }
                            .buttonStyle(.kizba(.ghost, size: .compact))
                            .accessibilityIdentifier("copy-meta-\(index)-button")
                    }
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Notes")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)

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
