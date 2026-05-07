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

    init(environment: AppEnvironment, state: AppState) {
        self.state = state
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
                FailedView(error: error)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
            // Diagnostics screen lands in Phase 8; stub the affordance.
            Button("View details") {}
                .disabled(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var title: String {
        switch error {
        case .binaryNotFound:        return "Required binary not found"
        case .pinentryNotConfigured: return "pinentry is not configured"
        case .decryptionFailed:      return "Decryption failed"
        case .storeNotFound:         return "Password store not found"
        case .timedOut:              return "The operation timed out"
        case .shellFailure:          return "Shell command failed"
        case .parsingFailed:         return "Could not parse decrypted body"
        case .cancelled:             return "Cancelled"
        }
    }

    private var message: String {
        switch error {
        case .binaryNotFound(let name):
            return "Could not find “\(name)” on PATH. Configure an override in Settings."
        case .pinentryNotConfigured:
            return "Install and configure pinentry-mac to decrypt entries."
        case .decryptionFailed:
            return "GPG could not decrypt this entry."
        case .storeNotFound(let path):
            return "Configured store path does not exist: \(path)"
        case .timedOut:
            return "The decrypt invocation exceeded its deadline."
        case .shellFailure(let code, _):
            return "Underlying command exited with code \(code)."
        case .parsingFailed(let reason):
            return reason
        case .cancelled:
            return "Operation was cancelled."
        }
    }
}
