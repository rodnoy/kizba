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
                placeholder("Select an entry")
            case .loading:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let secret):
                LoadedSecretView(
                    secret: secret,
                    isRevealed: $model.isPasswordRevealed,
                    onCopyPassword: { Task { await model.copyPassword() } },
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

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loaded state

private struct LoadedSecretView: View {
    let secret: PassSecret
    @Binding var isRevealed: Bool
    let onCopyPassword: () -> Void
    let onCopyField: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                passwordSection
                if !secret.metadata.fields.isEmpty {
                    Divider()
                    metadataSection
                }
                if let notes = secret.metadata.notes, !notes.isEmpty {
                    Divider()
                    notesSection(notes)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(isRevealed ? secret.password : String(repeating: "•", count: 12))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                Spacer()
                Button(isRevealed ? "Hide" : "Reveal") {
                    isRevealed.toggle()
                }
                Button("Copy", action: onCopyPassword)
                    .accessibilityIdentifier("copy-password-button")
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Metadata")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(Array(secret.metadata.fields.enumerated()), id: \.offset) { index, field in
                HStack(spacing: 8) {
                    Text("\(field.key):")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(field.value)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    Spacer()
                    Button("Copy") { onCopyField(field.value) }
                        .accessibilityIdentifier("copy-meta-\(index)-button")
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(notes)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Failed state

private struct FailedView: View {
    let error: PassError
    let environment: AppEnvironment

    @State private var showingDiagnostics = false
    @State private var diagnosticsModel: DiagnosticsModel? = nil

    var body: some View {
        let presentation = ErrorPresentation.present(for: error)
        VStack(alignment: .leading, spacing: 12) {
            switch presentation {
            case .emptyState(let nudge):
                Text(nudge.title)
                    .font(.headline)
                Text("Configure the missing tool in Settings to continue.")
                    .foregroundStyle(.secondary)
                #if canImport(AppKit)
                Button(nudge.actionTitle) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                #endif

            case .banner(let message, let helpURL):
                Text(message)
                    .padding(8)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                if let url = helpURL {
                    Link("Help", destination: url)
                }

            case .inlineWithDiagnostics(let message), .toastWithDiagnostics(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                Button("View details") {
                    diagnosticsModel = DiagnosticsModel(invocationLog: environment.invocationLog ?? InvocationLog())
                    showingDiagnostics = true
                }

            case .onboarding(let message):
                Text(message)
                    .foregroundStyle(.secondary)
                #if canImport(AppKit)
                Button("Open Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                #endif

            case .silent:
                EmptyView()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showingDiagnostics) {
            if let model = diagnosticsModel {
                DiagnosticsView(model: model)
                    .task {
                        await model.refresh()
                    }
            } else {
                Text("Loading…")
            }
        }
    }
}
