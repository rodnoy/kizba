//
//  EntryFormModel.swift
//  Kizba
//
//  Phase F.2 / G.2 — `@Observable @MainActor` form model backing the
//  New / Edit Entry sheet. F.2 implemented the `.create` mode used by
//  `NewEntrySheet`; G.2 wires the `.edit(originalPath:)` mode used by
//  `EditEntrySheet`. Per `.ai/decisions.md` there is NO separate
//  `edit` method on `PassManaging` — edit is composed in this model
//  as `pass show` (initial load) followed by `pass insert(force:true)`
//  on save. The protocol stays minimal and matches the `pass` verb
//  surface.
//
//  Lifecycle (create):
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
//  Lifecycle (edit) — Phase G.2:
//
//    1. Caller constructs the model with `.edit(originalPath:)` and
//       any `initialPath` is ignored (the originalPath wins). The
//       model immediately enters `.loadingExisting` and spawns a
//       task that runs `passManager.show(entry)` to fetch the
//       cleartext body.
//    2. On success the draft is replaced with `SecretDraft(from:)`
//       and the state transitions to `.editing`.
//    3. On failure the model lands in `.failed(error)` and posts an
//       error toast — the view replaces the form with a banner /
//       empty state because there is no point editing an entry the
//       backend could not load.
//    4. ``save()`` always passes `force: true` to `passManager.insert`
//       (the user is updating an entry that already exists); the
//       `forceOverwrite` flag is unused in edit mode.
//    5. On success the model lands in `.saved(path: originalPath)`
//       and posts a "Changes saved" toast. Selection is NOT mutated
//       — the user is already on this entry.
//    6. The path field is non-editable in edit mode (renaming is the
//       Move feature, G.4); the view consults ``canEditPath`` to
//       decide.
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
    /// currently issuing a save and not still loading the existing
    /// secret (edit mode).
    var canSave: Bool {
        guard pathError == nil,
              metadataError == nil,
              passwordError == nil
        else { return false }
        switch state {
        case .saving, .loadingExisting:
            return false
        default:
            return true
        }
    }

    /// `true` when the user may edit ``path`` directly. In `.create`
    /// mode the user types the path; in `.edit` mode the path is the
    /// identity of the entry being updated and renaming belongs to
    /// the Move feature (G.4) — so the field is read-only.
    var canEditPath: Bool {
        if case .create = mode { return true }
        return false
    }

    // MARK: - Dependencies

    private let passManager: any PassManaging
    private let toastCenter: ToastCenter
    private let appState: AppState

    // MARK: - In-flight save tracking

    /// Generation counter for in-flight saves AND in-flight loads
    /// (edit mode). Each new ``save()`` / ``loadExistingSecret()``
    /// bumps it; stale completions compare their captured value
    /// before mutating `state`. Combined with task cancellation this
    /// guards against rapid double-saves clobbering the UI with the
    /// older outcome AND against a late `pass show` arriving after
    /// the user has already cancelled the sheet.
    private var generation: UInt64 = 0
    private var saveTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

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

        switch mode {
        case .create:
            self.path = initialPath
            // Create starts directly in `.editing` — there is no
            // backend round-trip required before the user can type.
            self.state = .editing
        case .edit(let originalPath):
            // The original path wins over `initialPath` — for an
            // edit, the entry's identity is the path being updated.
            self.path = originalPath
            self.state = .loadingExisting
            // Spawn the load AFTER `self` is fully initialised. Bump
            // the generation so a (theoretical) concurrent save does
            // not race the load — `loadExistingSecret` captures its
            // own generation snapshot.
            self.loadTask = Task { [weak self] in
                await self?.loadExistingSecret(originalPath: originalPath)
            }
        }
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

        // Edit mode targets the originalPath the model was
        // constructed with; the path field is non-editable so this
        // is also `self.path`, but resolving from the mode keeps
        // the contract obvious.
        let resolvedPath: String
        let force: Bool
        switch mode {
        case .create:
            resolvedPath = path
            force = forceOverwrite
        case .edit(let originalPath):
            resolvedPath = originalPath
            // Edit always overwrites — the user is updating an
            // entry that, by construction, exists. The form's
            // `forceOverwrite` flag is unused in this branch.
            force = true
        }

        let entry = PassEntry(path: resolvedPath)
        let secretSnapshot = draft.snapshot()

        state = .saving

        // Phase G.6 — mark the op as in flight so the toolbars /
        // menu items disable other write surfaces. The op is
        // released in EVERY completion branch below (success,
        // typed failure, generic failure, cancellation) so the
        // begin/end pair is balanced regardless of how the task
        // resolves.
        let op = activeWriteOp(for: mode)
        appState.beginWrite(op)

        let manager = passManager
        // Capture appState locally so the completion-time
        // ``endWrite(_:)`` call does not depend on `self` still
        // being alive (the model may be deallocated mid-flight if
        // the sheet is dismissed before the save resolves).
        let capturedAppState = appState

        saveTask = Task { [weak self] in
            var cancelled = false
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
                let wrapped = PassError.writeFailed(reason: nil)
                self?.applyFailure(
                    error: wrapped,
                    generation: myGeneration
                )
            }
            // Phase G.6 — release the op on natural completion
            // (success / typed failure / generic failure). When the
            // task was cancelled the lockout was already released
            // by ``cancel()`` / ``handleDismissal()``; releasing it
            // again here would double-decrement and (in pathological
            // cancel + immediate-resave sequences) prematurely free
            // a still-in-flight successor's lockout.
            if !cancelled {
                await MainActor.run {
                    capturedAppState.endWrite(op)
                }
            }
        }
    }

    /// Map the current ``mode`` to the corresponding
    /// ``ActiveWriteOp`` case (Phase G.6). `.create` mode emits
    /// `.insertNew`, `.edit` mode emits `.edit`.
    private func activeWriteOp(for mode: Mode) -> ActiveWriteOp {
        if case .create = mode { return .insertNew }
        return .edit
    }

    /// Cancel any in-flight save / load and revert UI to the editing
    /// state. Does NOT clear ``path`` / ``draft`` — the user may be
    /// cancelling the network attempt, not the form. Use
    /// ``handleDismissal()`` for the full reset.
    func cancel() {
        let hadInFlightSave = (saveTask != nil)
        saveTask?.cancel()
        saveTask = nil
        loadTask?.cancel()
        loadTask = nil
        // Bump the generation so any late completion from the
        // cancelled task cannot mutate state.
        generation &+= 1
        forceOverwrite = false
        state = .editing
        // Phase G.6 — release the lockout synchronously so a follow-
        // up `save()` can claim it cleanly. The cancelled save task
        // detects its `CancellationError` and skips its own
        // ``endWrite(_:)`` call (the cancellation flag is set
        // inside the Task body), so this synchronous release is the
        // sole path for the cancelled op.
        if hadInFlightSave {
            appState.endWrite(activeWriteOp(for: mode))
        }
    }

    /// Called by the view on sheet dismissal. Cancels the save and
    /// load tasks and replaces ``draft`` with a fresh empty draft so
    /// the prior cleartext password / metadata / notes are dropped
    /// from this model. Resets ``path`` and ``forceOverwrite`` too.
    func handleDismissal() {
        let hadInFlightSave = (saveTask != nil)
        saveTask?.cancel()
        saveTask = nil
        loadTask?.cancel()
        loadTask = nil
        generation &+= 1
        // Replace the draft entirely; ARC drops the old instance
        // and any references the view held to its mutable fields
        // become orphaned.
        draft = SecretDraft()
        path = ""
        forceOverwrite = false
        state = .editing
        // Phase G.6 — release the lockout synchronously (same
        // rationale as ``cancel()``).
        if hadInFlightSave {
            appState.endWrite(activeWriteOp(for: mode))
        }
    }

    // MARK: - Edit-mode load

    /// Pre-fetches the existing secret for the entry being edited
    /// and pours it into ``draft`` via `SecretDraft(from:)`. Runs at
    /// init time when ``mode`` is `.edit(originalPath:)`.
    ///
    /// Uses the same generation-counter pattern as ``save()`` so a
    /// rapid cancel + dismiss sequence cannot land a stale draft
    /// after the user has moved on.
    private func loadExistingSecret(originalPath: String) async {
        // Capture our own generation before issuing the show. A
        // concurrent ``save()`` (theoretical — the view disables
        // Save while loading) or ``cancel()`` will bump the counter
        // and our completion will be discarded.
        generation &+= 1
        let myGeneration = generation
        let entry = PassEntry(path: originalPath)
        let manager = passManager

        do {
            let secret = try await manager.show(entry)
            try Task.checkCancellation()
            applyLoadSuccess(
                secret: secret,
                generation: myGeneration
            )
        } catch is CancellationError {
            // Cancelled — `cancel()` / `handleDismissal()` already
            // restored the UI; nothing to do.
        } catch let passError as PassError {
            applyLoadFailure(
                error: passError,
                generation: myGeneration
            )
        } catch {
            // Unexpected non-PassError — surface as a generic
            // decryption-failed so the view shows a banner.
            applyLoadFailure(
                error: .decryptionFailed(stderrExcerpt: ""),
                generation: myGeneration
            )
        }
    }

    private func applyLoadSuccess(
        secret: PassSecret,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        // Replace the draft wholesale — the previous (empty) draft
        // is dropped along with any references the view held.
        draft = SecretDraft(from: secret)
        state = .editing
    }

    private func applyLoadFailure(
        error: PassError,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        state = .failed(error)
        // Initial-load failure is never inline-recoverable from the
        // form's perspective — there is nothing to retry without a
        // separate Diagnostics path. Always toast the error.
        toastCenter.post(
            Toast(
                severity: .danger,
                title: "Could not load entry",
                message: Self.userFacingMessage(for: error)
            )
        )
    }

    // MARK: - Completion plumbing

    private func applySuccess(
        savedPath: String,
        generation taskGeneration: UInt64
    ) {
        guard taskGeneration == self.generation else { return }
        state = .saved(path: savedPath)
        // Defensive: clear the overwrite flag so a subsequent save
        // through the same model doesn't carry it forward.
        forceOverwrite = false

        switch mode {
        case .create:
            // Phase F.5 — select the freshly-created entry.
            //
            // Ordering invariant: the selection is set BEFORE the
            // `EntryListModel.observeChanges` handler observes the
            // matching `.inserted` event from `passManager.changes`
            // and re-lists. Both this code path and the
            // changes-subscription run on the MainActor, so by the
            // time the list refresh completes the selection is
            // already in place — the row will render as selected as
            // soon as it appears. Phase H owns selection-on-event
            // rules in full; F.5 keeps this imperative set so the
            // UI experience does not depend on event delivery
            // latency.
            appState.selectedEntryID = savedPath
            toastCenter.post(
                Toast(
                    severity: .success,
                    title: "Entry created",
                    message: savedPath
                )
            )
        case .edit:
            // Edit does NOT mutate `selectedEntryID` — the user is
            // already on this entry. The `EntryDetailModel` will
            // re-fetch on the next `.updated(path)` event from the
            // changes stream (Phase F.5 list refresh + Phase H
            // selection rules cover the detail-side reload).
            toastCenter.post(
                Toast(
                    severity: .success,
                    title: "Changes saved",
                    message: savedPath
                )
            )
        }
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
