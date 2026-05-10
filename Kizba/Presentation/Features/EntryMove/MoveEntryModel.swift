//
//  MoveEntryModel.swift
//  Kizba
//
//  Phase G.4 — `@Observable @MainActor` view-model backing the
//  `MoveEntrySheet` reachable from `EntryListView`'s ↔ toolbar
//  button and the `Entry > Move Entry…` menu item (⌘⇧M).
//
//  Mechanism
//  ---------
//
//  Wraps a single `passManager.move(from:to:force:)` call. The user
//  edits ``newPath`` (pre-filled with the entry's current path); on
//  Save the model invokes the manager, then on success records the
//  inverse in ``ActionHistory`` (10s window) and posts a success
//  toast carrying an Undo action that calls back into the same
//  history.
//
//  Collision is recoverable inline: when the manager throws
//  ``PassError/entryAlreadyExists(path:)`` the sheet renders a
//  warning banner with a "Replace" button that flips
//  ``forceMove = true`` and re-invokes ``save()``. Mirrors the
//  collision pattern used by `EntryFormModel` for Overwrite.
//
//  Selection follow-on
//  -------------------
//
//  Phase H will own systematic selection reconciliation against
//  `pass.changes`. For G.4 we set
//  `appState.selectedEntryID = newEntry.path` imperatively after
//  success so the UI experience does not depend on event-delivery
//  latency. Same imperative pattern as Phase F.5.
//
//  Lifecycle
//  ---------
//
//  Constructed per-presentation by `EntryListView`'s
//  `.sheet(isPresented:)`; SwiftUI tears it down on dismiss.
//  ``handleDismissal()`` cancels any in-flight save so a late
//  completion cannot mutate UI after the user has moved on.
//
//  Per `.ai/decisions.md`, success and error toasts NEVER carry
//  secret material — only entry paths.
//

import Foundation
import Observation

/// `@Observable` view-model backing ``MoveEntrySheet``.
@Observable
@MainActor
final class MoveEntryModel {

    // MARK: - State

    /// Discrete UI phase. Validation failures keep the model in
    /// ``State/idle`` and surface inline via ``pathError`` — only
    /// backend (`PassError`) failures land in ``State/failed(_:)``.
    enum State: Sendable, Equatable {
        case idle
        case saving
        case saved(newPath: String)
        case failed(PassError)
    }

    // MARK: - Public observable state

    /// Current pipeline phase. Mutated only via ``save()`` /
    /// ``cancel()`` / ``handleDismissal()``.
    private(set) var state: State = .idle

    /// User-typed destination path. Pre-filled with the original
    /// entry's path so a spurious save (without the user touching
    /// the field) is caught by the "same path" validator below.
    /// Bound directly by the view's `FolderPathPicker`.
    var newPath: String

    /// Set to `true` by the view when the user clicks "Replace"
    /// after seeing the collision banner. Re-invoking ``save()``
    /// then passes `force: true` to the CLI. Reset to `false` on
    /// successful save and on ``cancel()`` / ``handleDismissal()``.
    var forceMove: Bool = false

    // MARK: - Inputs

    /// Original entry being moved. Snapshot at construction time.
    let originalEntry: PassEntry

    // MARK: - Computed validators (synchronous, recomputed on read)

    /// Localised error message for ``newPath`` (or `nil` when valid).
    /// Layers an additional "same path as original" rule on top of
    /// the shared ``EntryPathValidator`` — pass treats paths case-
    /// sensitively on macOS, so a simple string equality check is
    /// the right semantics.
    var pathError: String? {
        // Defer the same-path rule until AFTER a syntactic-validity
        // pass: an invalid path that happens to equal the original
        // should report "drop the .gpg suffix" / etc., not
        // "destination is the same".
        switch EntryPathValidator.validate(newPath) {
        case .failure(let error):
            return Self.message(for: error)
        case .success:
            if newPath == originalEntry.path {
                return "Destination is the same as the current path."
            }
            return nil
        }
    }

    /// `true` when ``pathError`` is `nil` AND the model is not
    /// currently issuing a save. The view binds the Save button's
    /// `.disabled(...)` to `!canSave`.
    var canSave: Bool {
        guard pathError == nil else { return false }
        switch state {
        case .saving:
            return false
        case .idle, .saved, .failed:
            return true
        }
    }

    // MARK: - Dependencies

    private let passManager: any PassManaging
    private let actionHistory: ActionHistory
    private let toastCenter: ToastCenter
    private let appState: AppState

    // MARK: - In-flight tracking

    /// Generation counter for in-flight saves. Each ``save()``
    /// bumps it; stale completions compare their captured value
    /// before mutating ``state`` so a rapid double-save cannot
    /// clobber the UI with the older outcome.
    private var generation: UInt64 = 0
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    init(
        originalEntry: PassEntry,
        passManager: any PassManaging,
        actionHistory: ActionHistory,
        toastCenter: ToastCenter,
        appState: AppState
    ) {
        self.originalEntry = originalEntry
        self.passManager = passManager
        self.actionHistory = actionHistory
        self.toastCenter = toastCenter
        self.appState = appState
        // Pre-fill with the original path so the picker shows
        // something immediately. The "same path" rule keeps
        // ``canSave`` `false` until the user actually edits.
        self.newPath = originalEntry.path
    }

    // MARK: - Actions

    /// Validate, then invoke `passManager.move(from:to:force:)` on
    /// a cancellable task. Cancels any prior save first.
    ///
    /// Validation failures keep `state == .idle` and surface inline
    /// via ``pathError`` — they do NOT set `state = .failed`. Only
    /// backend (`PassError`) failures transition to
    /// ``State/failed(_:)``.
    func save() {
        // Validation gate. The view should disable Save while
        // `pathError` is non-nil; this guard is the second line of
        // defence (and covers programmatic callers).
        guard pathError == nil else { return }

        // Cancel any prior save + bump generation so its result
        // (if it arrives) is silently ignored by the
        // applySuccess / applyFailure helpers.
        saveTask?.cancel()
        generation &+= 1
        let myGeneration = generation

        let manager = passManager
        let from = originalEntry
        let to = newPath
        let force = forceMove

        state = .saving

        // Phase G.6 — mark the move op as in flight so the toolbars
        // / menu items disable other write surfaces. The op is
        // released on natural completion (success / typed failure /
        // generic failure); when the task is cancelled the lockout
        // is released synchronously by ``cancel()`` /
        // ``handleDismissal()`` so a follow-up `save()` can claim
        // it cleanly.
        appState.beginWrite(.move)
        // Capture appState locally so the completion-time
        // ``endWrite(_:)`` call does not depend on `self` still
        // being alive (the model may be deallocated mid-flight if
        // the sheet is dismissed before the save resolves).
        let capturedAppState = appState

        saveTask = Task { [weak self] in
            var cancelled = false
            do {
                let newEntry = try await manager.move(
                    from: from,
                    to: to,
                    force: force
                )
                try Task.checkCancellation()
                self?.applySuccess(
                    originalPath: from.path,
                    newEntry: newEntry,
                    generation: myGeneration
                )
            } catch is CancellationError {
                // Cancelled — nothing to do; `cancel()` /
                // `handleDismissal()` already restored the UI AND
                // released the lockout via ``endWrite(_:)``.
                cancelled = true
            } catch let passError as PassError {
                self?.applyFailure(
                    error: passError,
                    generation: myGeneration
                )
            } catch {
                // Defensive — `PassManaging` is contractually typed-
                // throw `PassError`, but we wrap the generic case
                // in case the contract ever loosens.
                let wrapped = PassError.writeFailed(reason: nil)
                self?.applyFailure(
                    error: wrapped,
                    generation: myGeneration
                )
            }
            if !cancelled {
                await MainActor.run {
                    capturedAppState.endWrite(.move)
                }
            }
        }
    }

    /// Cancel any in-flight save and revert UI to the idle state.
    /// Does NOT clear ``newPath`` — the user may be cancelling
    /// the network attempt, not the form. Use ``handleDismissal()``
    /// for the per-dismiss reset.
    func cancel() {
        let hadInFlightSave = (saveTask != nil)
        saveTask?.cancel()
        saveTask = nil
        // Bump the generation so any late completion from the
        // cancelled task cannot mutate state.
        generation &+= 1
        forceMove = false
        state = .idle
        // Phase G.6 — release the lockout synchronously so a follow-
        // up `save()` can claim it cleanly. The cancelled save task
        // detects its `CancellationError` and skips its own
        // ``endWrite(_:)`` call.
        if hadInFlightSave {
            appState.endWrite(.move)
        }
    }

    /// Called by the view on sheet dismissal. Cancels the save
    /// task. ``newPath`` is intentionally NOT cleared — the model
    /// is per-presentation, so SwiftUI drops the whole instance on
    /// dismiss, and a transient re-presentation should not lose
    /// the user's typed value mid-flight.
    func handleDismissal() {
        let hadInFlightSave = (saveTask != nil)
        saveTask?.cancel()
        saveTask = nil
        generation &+= 1
        // Phase G.6 — release the lockout synchronously (same
        // rationale as ``cancel()``).
        if hadInFlightSave {
            appState.endWrite(.move)
        }
    }

    // MARK: - Completion plumbing

    private func applySuccess(
        originalPath: String,
        newEntry: PassEntry,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        state = .saved(newPath: newEntry.path)
        // Defensive: clear the overwrite flag so a subsequent save
        // through the same model doesn't carry it forward.
        forceMove = false

        // Phase G.4 — selection follows the entry to its new path.
        // Imperative set (same pattern as Phase F.5); systematic
        // selection-on-event reconciliation is Phase H's concern.
        appState.router.selectedEntryID = newEntry.path

        // Record the inverse FIRST so the toast's Undo action has
        // something to consume, THEN post the toast.
        actionHistory.record(
            .move(from: originalPath, to: newEntry.path),
            expiresAfter: .seconds(10)
        )

        // Capture the action history reference into a local so the
        // closure does not need to capture `self` — keeps the
        // Sendable check on `BannerAction` clean and avoids retain
        // cycles via the model.
        let history = actionHistory
        let undoAction = BannerView.BannerAction(label: "Undo") {
            // Fire-and-forget. `ActionHistory.undoLast()` clears
            // `pending` even on failure (per its contract), so the
            // user can move on. A future polish pass could surface
            // the failure as a fresh error toast.
            Task { try? await history.undoLast() }
        }

        let toast = Toast(
            severity: .success,
            title: "Entry moved",
            // Per `.ai/decisions.md`, toasts NEVER carry secret
            // material — only the entry path is permitted.
            message: "Now at \(newEntry.path)",
            action: undoAction
        )
        toastCenter.post(toast)
    }

    private func applyFailure(
        error: PassError,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        state = .failed(error)
        // `entryAlreadyExists` is recoverable inline via the
        // sheet's collision banner — do NOT post a toast (the
        // banner handles UI). Selection is left untouched.
        if error.inlineRecoverable {
            return
        }
        toastCenter.post(
            Toast(
                severity: .danger,
                title: "Move failed",
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

    /// Short, user-facing message for a `PassError` surfaced through
    /// a toast. The CLI/stderr excerpt is deliberately omitted —
    /// toasts must not carry secret material and the Diagnostics
    /// view is the right place for raw output.
    private static func userFacingMessage(for error: PassError) -> String {
        switch error {
        case .entryAlreadyExists(let path):
            // Not normally toasted (inlineRecoverable); included
            // for completeness in case a future call site posts it.
            return "An entry already exists at \(path)."
        case .recipientNotFound(let id):
            return "GPG cannot find a public key for \(id)."
        case .invalidGpgId:
            return "The store's GPG recipients are not configured."
        case .sourceNotFound(let path):
            return "The entry \(path) is no longer in the store."
        case .invalidLength:
            return "The requested length was rejected."
        case .writeFailed(let reason):
            if let reason, !reason.isEmpty {
                return "Move failed: \(reason)."
            }
            return "Move failed."
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
