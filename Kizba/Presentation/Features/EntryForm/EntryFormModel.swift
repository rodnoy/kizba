//
//  EntryFormModel.swift
//  Kizba
//
//  Phase F.2 — `@Observable @MainActor` form model backing the
//  New / Edit Entry sheet. F.2 implements the `.create` mode only
//  (used by `NewEntrySheet` in F.3); `.edit(originalPath:)` is
//  reserved for Phase G.2.
//
//  Lifecycle:
//
//    1. SwiftUI constructs the model when the sheet appears.
//    2. The view binds to `path`, `draft.password`, `draft.metadata`,
//       `draft.notes` directly (`SecretDraft` is a class so SwiftUI
//       sees mutations without per-keystroke struct copies).
//    3. The view reads `pathError`, `metadataError`, `passwordError`
//       and `canSave` to drive inline errors and the Save button's
//       disabled state.
//    4. On Save → ``save()`` validates (gates the call), then runs
//       `passManager.insert(...)` on a cancellable Task tracked by
//       a generation counter (mirrors `EntryDetailModel`).
//    5. On `entryAlreadyExists` the form stays open; the view shows
//       a banner with an "Overwrite" button that flips
//       `forceOverwrite = true` and re-invokes ``save()``.
//    6. On dismissal → ``handleDismissal()`` cancels the save task
//       and replaces the draft so any cleartext payload is dropped.
//
//  Per `.ai/decisions.md`, success and error toasts NEVER carry
//  secret material — only the entry path / human-readable status.
//

import Foundation
import Observation

/// `@Observable` view-model for the New / Edit Entry sheet.
///
/// `internal` access matches `AppState` and `AppEnvironment`: this
/// model is part of the Presentation layer and is wired by the same
/// internal SwiftUI surface.
@Observable
@MainActor
final class EntryFormModel {

    // MARK: - Mode + State

    /// Form mode. F.2 covers ``Mode/create`` only; ``Mode/edit`` is
    /// reserved for Phase G.2 (`EditEntrySheet`).
    enum Mode: Sendable, Equatable {
        case create
        case edit(originalPath: String)
    }

    /// Discrete UI phase. `.loadingExisting` is reserved for the
    /// edit pre-fetch Phase G.2 will introduce; create starts in
    /// `.editing` immediately. Validation failures keep the model in
    /// `.editing` and surface inline via `pathError`/etc — only
    /// backend (`PassError`) failures land in `.failed(_)`.
    enum State: Sendable, Equatable {
        case idle
        case loadingExisting
        case editing
        case saving
        case saved(path: String)
        case failed(PassError)
    }

    // MARK: - Public observable state

    /// Current form mode. Immutable after init.
    private(set) var mode: Mode

    /// Current UI phase; observed by the view.
    private(set) var state: State = .editing

    /// User-typed entry path (e.g. `"work/aws/root"`). Bound directly
    /// by the view's TextField; validated synchronously on every read
    /// of ``pathError``/``canSave``.
    var path: String

    /// Mutable working secret. The view binds to its `password`,
    /// `metadata` and `notes` directly.
    private(set) var draft: SecretDraft

    /// Set to `true` by the view when the user clicks "Overwrite"
    /// after seeing the collision banner. Re-invoking ``save()`` then
    /// passes `force: true` to the CLI. Reset to `false` on
    /// successful save and on ``cancel()`` / ``handleDismissal()``.
    var forceOverwrite: Bool = false

    // MARK: - Computed validators (synchronous, recomputed on read)

    /// Localized error message for ``path`` (or `nil` when valid).
    var pathError: String? {
        switch EntryPathValidator.validate(path) {
        case .success:
            return nil
        case .failure(let error):
            return Self.message(for: error)
        }
    }

    /// Localized error message for ``draft``'s metadata (or `nil`
    /// when valid).
    var metadataError: String? {
        switch MetadataValidator.validate(draft.metadata) {
        case .success:
            return nil
        case .failure(let error):
            return Self.message(for: error)
        }
    }

    /// Localized error message for ``draft``'s password (or `nil`
    /// when non-empty).
    var passwordError: String? {
        draft.password.isEmpty ? "Password cannot be empty." : nil
    }

    /// `true` when every validator passes AND the model is not
    /// currently issuing a save.
    var canSave: Bool {
        guard pathError == nil,
              metadataError == nil,
              passwordError == nil
        else { return false }
        if case .saving = state { return false }
        return true
    }

    // MARK: - Dependencies

    private let passManager: any PassManaging
    private let toastCenter: ToastCenter
    private let appState: AppState

    // MARK: - In-flight save tracking

    /// Generation counter for in-flight saves. Each new ``save()``
    /// bumps it; stale completions compare their captured value
    /// before mutating `state`. Combined with task cancellation this
    /// guards against rapid double-saves clobbering the UI with the
    /// older outcome.
    private var generation: UInt64 = 0
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    init(
        mode: Mode = .create,
        passManager: any PassManaging,
        toastCenter: ToastCenter,
        appState: AppState,
        initialDraft: SecretDraft? = nil,
        initialPath: String = ""
    ) {
        self.mode = mode
        self.passManager = passManager
        self.toastCenter = toastCenter
        self.appState = appState
        self.draft = initialDraft ?? SecretDraft()
        self.path = initialPath
        // F.2 ships `.create` only — start directly in `.editing`.
        self.state = .editing
    }

    // MARK: - Actions

    /// Validate, then call `passManager.insert(...)`. Cancels any
    /// in-flight save first.
    ///
    /// Validation failures keep `state == .editing` and surface
    /// inline via the computed validators — they do NOT set
    /// `state = .failed`. Only backend (`PassError`) failures
    /// transition to `.failed(error)`.
    func save() {
        // Validation gate. The view should disable Save while
        // anything is invalid; this guard is the second line of
        // defence (and covers programmatic callers).
        guard pathError == nil,
              metadataError == nil,
              passwordError == nil
        else {
            return
        }

        // Cancel any prior save + bump generation so its result
        // (if it arrives) is silently ignored.
        saveTask?.cancel()
        generation &+= 1
        let myGeneration = generation

        let entry = PassEntry(path: path)
        let secretSnapshot = draft.snapshot()
        let force = forceOverwrite

        state = .saving

        let manager = passManager

        saveTask = Task { [weak self] in
            do {
                let saved = try await manager.insert(
                    entry,
                    secret: secretSnapshot,
                    force: force
                )
                try Task.checkCancellation()
                self?.applySuccess(
                    savedPath: saved.path,
                    generation: myGeneration
                )
            } catch is CancellationError {
                // Cancelled — nothing to do; `cancel()` already
                // restored the UI to `.editing`.
            } catch let passError as PassError {
                self?.applyFailure(
                    error: passError,
                    generation: myGeneration
                )
            } catch {
                let wrapped = PassError.writeFailed(reason: nil)
                self?.applyFailure(
                    error: wrapped,
                    generation: myGeneration
                )
            }
        }
    }

    /// Cancel any in-flight save and revert UI to the editing state.
    /// Does NOT clear ``path`` / ``draft`` — the user may be
    /// cancelling the network attempt, not the form. Use
    /// ``handleDismissal()`` for the full reset.
    func cancel() {
        saveTask?.cancel()
        saveTask = nil
        // Bump the generation so any late completion from the
        // cancelled task cannot mutate state.
        generation &+= 1
        forceOverwrite = false
        state = .editing
    }

    /// Called by the view on sheet dismissal. Cancels the save task
    /// and replaces ``draft`` with a fresh empty draft so the prior
    /// cleartext password / metadata / notes are dropped from this
    /// model. Resets ``path`` and ``forceOverwrite`` too.
    func handleDismissal() {
        saveTask?.cancel()
        saveTask = nil
        generation &+= 1
        // Replace the draft entirely; ARC drops the old instance
        // and any references the view held to its mutable fields
        // become orphaned.
        draft = SecretDraft()
        path = ""
        forceOverwrite = false
        state = .editing
    }

    // MARK: - Completion plumbing

    private func applySuccess(
        savedPath: String,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        state = .saved(path: savedPath)
        // Defensive: clear the overwrite flag so a subsequent edit
        // through the same model doesn't carry it forward.
        forceOverwrite = false
        // Phase F.5 — select the freshly-created entry.
        //
        // Ordering invariant: the selection is set BEFORE the
        // `EntryListModel.observeChanges` handler observes the
        // matching `.inserted` event from `passManager.changes` and
        // re-lists. Both this code path and the changes-subscription
        // run on the MainActor, so by the time the list refresh
        // completes the selection is already in place — the row will
        // render as selected as soon as it appears. Phase H owns
        // selection-on-event rules in full; F.5 keeps this
        // imperative set so the UI experience does not depend on
        // event delivery latency.
        appState.selectedEntryID = savedPath
        toastCenter.post(
            Toast(
                severity: .success,
                title: "Entry created",
                message: savedPath
            )
        )
    }

    private func applyFailure(
        error: PassError,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        state = .failed(error)
        // `entryAlreadyExists` is recoverable inline via the form's
        // banner — do NOT post a toast (the banner handles UI).
        if error.inlineRecoverable {
            return
        }
        toastCenter.post(
            Toast(
                severity: .danger,
                title: "Save failed",
                message: Self.userFacingMessage(for: error)
            )
        )
    }

    // MARK: - Localised strings (English-only for MVP; i18n is post-MVP)

    private static func message(
        for error: EntryPathValidator.ValidationError
    ) -> String {
        switch error {
        case .empty:
            return "Path cannot be empty."
        case .leadingSlash:
            return "Path cannot begin with a slash."
        case .trailingSlash:
            return "Path cannot end with a slash."
        case .dotComponent:
            return "Path components cannot be \".\"."
        case .dotDotComponent:
            return "Path components cannot be \"..\"."
        case .gpgSuffix:
            return "Drop the \".gpg\" suffix — pass appends it automatically."
        case .whitespaceComponent:
            return "Path components cannot be empty or whitespace-only."
        }
    }

    private static func message(
        for error: MetadataValidator.ValidationError
    ) -> String {
        switch error {
        case .emptyKey(let index):
            return "Metadata key #\(index + 1) cannot be empty."
        case .keyContainsColon(let index):
            return "Metadata key #\(index + 1) cannot contain a colon."
        case .keyContainsNewline(let index):
            return "Metadata key #\(index + 1) cannot contain a newline."
        case .duplicateKey(let index, let prior):
            return "Metadata key #\(index + 1) duplicates key #\(prior + 1)."
        }
    }

    /// Short, user-facing message for a `PassError` surfaced through
    /// a toast. The CLI/stderr excerpt is deliberately omitted —
    /// toasts must not carry secret material and the Diagnostics
    /// view is the right place for raw output.
    private static func userFacingMessage(for error: PassError) -> String {
        switch error {
        case .entryAlreadyExists(let path):
            // Not normally toasted (inlineRecoverable); included for
            // completeness in case a future call site posts it.
            return "An entry already exists at \(path)."
        case .recipientNotFound(let id):
            return "GPG cannot find a public key for \(id)."
        case .invalidGpgId:
            return "The store's GPG recipients are not configured."
        case .sourceNotFound(let path):
            return "The entry \(path) is no longer in the store."
        case .invalidLength:
            return "The requested password length was rejected."
        case .writeFailed(let reason):
            if let reason, !reason.isEmpty {
                return "Write failed: \(reason)."
            }
            return "Write failed."
        case .timedOut:
            return "The operation timed out."
        case .shellFailure(let exitCode, _):
            return "pass exited with code \(exitCode)."
        case .decryptionFailed:
            return "Decryption failed."
        case .parsingFailed(let reason):
            return "Could not parse pass output: \(reason)"
        case .storeNotFound(let path):
            return "Password store not found at \(path)."
        case .binaryNotFound(let name):
            return "Required binary \(name) was not found."
        case .pinentryNotConfigured:
            return "pinentry is not configured."
        case .cancelled:
            return "Cancelled."
        }
    }
}
