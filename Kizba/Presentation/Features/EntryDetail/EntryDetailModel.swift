//
//  EntryDetailModel.swift
//  Kizba
//
//  Observable view model backing `EntryDetailView` (detail column of
//  the root `NavigationSplitView`). Owns the lifecycle of the
//  decrypted `PassSecret` for the currently selected entry: loads it
//  on demand via `PassManaging.show(_:)`, cancels in-flight loads
//  when the selection changes, and exposes copy-to-clipboard helpers.
//
//  Per `.ai/decisions.md`, `PassSecret` lives ONLY here — never on
//  `AppState`, never persisted, never logged.
//

import Foundation
import Observation

/// View model for `EntryDetailView`.
///
/// The model owns three pieces of state:
///
/// - ``state`` — discrete UI phase (idle / loading / loaded / failed).
/// - The most recently selected entry ID it began loading for, used
///   to detect selection churn.
/// - The currently in-flight `Task` (if any), so it can be cancelled
///   the instant the selection changes.
///
/// Driven by ``handleSelectionChange(_:)`` which the view invokes on
/// every change of `AppState.selectedEntryID`. Cancellation is
/// cooperative: the previous task is cancelled and its result, if it
/// arrives, is discarded by the generation check.
@Observable
@MainActor
final class EntryDetailModel {

    /// Discrete UI phase. Carries the loaded ``PassSecret`` only in
    /// ``State/loaded(_:)`` and only for the duration of the active
    /// selection — released on the next selection change.
    enum State: Sendable {
        case idle
        case loading
        case loaded(PassSecret)
        case failed(PassError)
    }

    /// Current UI phase; observed by the view.
    private(set) var state: State = .idle

    /// Whether the password is currently revealed in the UI. The view
    /// flips this; the model exposes it so toggling does not require a
    /// separate view-local `@State` that could outlive a selection.
    var isPasswordRevealed: Bool = false

    private let environment: AppEnvironment
    private let appState: AppState

    /// Generation counter for in-flight loads. Each new load increments
    /// it; stale tasks compare their captured value before mutating
    /// `state`. Combined with task cancellation this prevents late
    /// results from clobbering the UI after the user moved on.
    private var generation: UInt64 = 0
    private var loadTask: Task<Void, Never>?

    /// Long-lived subscription to `passManager.changes` (Phase H.1).
    /// Started by ``observeChanges()`` (typically driven by the view's
    /// `.task` modifier so cancellation is automatic on disappear) and
    /// optionally torn down by ``stop()`` for tests / programmatic
    /// detachment.
    private var changeSubscriptionTask: Task<Void, Never>?

    // MARK: - Password reveal gating

    /// Attempt to reveal the password, gated by the biometric setting
    /// and the injected authenticator. When the setting is off, or no
    /// authenticator is injected, reveal immediately. If biometrics are
    /// available, present the prompt and reveal only on success.
    public func requestReveal() async {
        // Fast-path: already revealed — no-op.
        guard !isPasswordRevealed else { return }

        let requireBio = environment.settings
            .value(for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)) ?? false

        guard requireBio, let auth = environment.biometricAuth else {
            // Setting disabled or no authenticator injected: reveal.
            isPasswordRevealed = true
            return
        }

        switch auth.isAvailable() {
        case .available:
            let result = await auth.authenticate(reason: "Reveal password")
            switch result {
            case .success:
                isPasswordRevealed = true
            case .cancelled, .failed(_):
                isPasswordRevealed = false
            }
        case .unavailable(_):
            // Graceful fallback when device reports biometrics
            // unavailable: reveal immediately.
            isPasswordRevealed = true
        }
    }

    init(environment: AppEnvironment, state: AppState) {
        self.environment = environment
        self.appState = state
    }

    // No `deinit` cancellation: `loadTask` is MainActor-isolated and
    // cannot be touched from a nonisolated context. Selection-change
    // and `nil`-selection paths already cancel the task explicitly.

    /// Begin (or cancel) a load in response to a selection change.
    ///
    /// Idempotent for repeated calls with the same `entryID` — the
    /// in-flight task is preserved. For a different ID (including
    /// `nil`), the previous task is cancelled and a new one is
    /// scheduled (or the model returns to ``State/idle`` on `nil`).
    func handleSelectionChange(_ entryID: PassEntry.ID?) {
        // Cancel any in-flight work and bump the generation so its
        // result, if it arrives, is ignored.
        loadTask?.cancel()
        loadTask = nil
        generation &+= 1
        isPasswordRevealed = false

        guard let entryID else {
            state = .idle
            return
        }

        let entry = PassEntry(path: entryID)
        let myGeneration = generation
        state = .loading

        let passManager = environment.passManager
        loadTask = Task { [weak self] in
            do {
                let secret = try await passManager.show(entry)
                try Task.checkCancellation()
                self?.apply(.loaded(secret), generation: myGeneration)
            } catch is CancellationError {
                self?.apply(.idle, generation: myGeneration, onlyIfCurrent: false)
            } catch let passError as PassError {
                if case .cancelled = passError {
                    self?.apply(.idle, generation: myGeneration, onlyIfCurrent: false)
                } else {
                    self?.apply(.failed(passError), generation: myGeneration)
                }
            } catch {
                self?.apply(
                    .failed(.shellFailure(exitCode: -1, stderrExcerpt: "")),
                    generation: myGeneration
                )
            }
        }
    }

    /// Identifies the semantic target of a copy operation so the
    /// confirmation toast can render a meaningful per-field label
    /// without ever surfacing the copied value itself. Per
    /// `.ai/decisions.md`, toasts NEVER carry secret material — only
    /// the field's role / key is permitted in the title.
    enum CopyTarget: Sendable, Equatable {
        case password
        case metadata(key: String)
        case notes
        /// Reserved for future arbitrary fields. The provided label
        /// is rendered as the toast title prefix.
        case other(label: String)

        /// Human-readable label rendered into the toast title. The
        /// metadata case quotes the key so a key like `email` reads
        /// `"email" copied` rather than `email copied` (which would
        /// look like a sentence fragment).
        var toastLabel: String {
            switch self {
            case .password: return "Password"
            case .metadata(let key): return "\"\(key)\""
            case .notes: return "Notes"
            case .other(let label): return label
            }
        }
    }

    /// Copy a single field's value to the system pasteboard with
    /// token-checked auto-clear, then post a confirmation toast
    /// labelled by `target`.
    ///
    /// The auto-clear delay is sampled live from
    /// ``SettingsStoring`` on every call (Phase A.6) so changes made
    /// in the Settings window take effect immediately, without
    /// reconstructing the model. Per `.ai/decisions.md`, the value is
    /// written verbatim — never composed with the field's key — and
    /// the confirmation toast carries ONLY the semantic label and
    /// the auto-clear window. The copied value never crosses the
    /// toast boundary.
    func copy(_ value: String, target: CopyTarget) async {
        let delay = currentClipboardClearDelay()
        await environment.clipboard.copy(value, clearAfter: delay)
        postCopyConfirmationToast(target: target, delay: delay)
    }

    /// Backward-compatible overload preserved for callers that have
    /// no semantic target (tests / Diagnostics-style usage). New
    /// view-layer call sites SHOULD prefer the typed
    /// ``copy(_:target:)`` overload so the user sees a confirmation
    /// toast.
    func copy(_ value: String) async {
        await environment.clipboard.copy(value, clearAfter: currentClipboardClearDelay())
    }

    /// Convenience: copy the loaded password if available. No-op if
    /// the model is not in ``State/loaded(_:)``. Posts an
    /// `.info` confirmation toast titled `"Password copied"`.
    func copyPassword() async {
        guard case .loaded(let secret) = state else { return }
        await copy(secret.password, target: .password)
    }

    /// Convenience: copy the first metadata value matching `key`.
    /// No-op if the model is not loaded or the key is absent. Posts
    /// an `.info` confirmation toast titled `"\"<key>\" copied"`.
    func copyMetadata(forKey key: String) async {
        guard case .loaded(let secret) = state,
              let value = secret.metadata.firstValue(for: key)
        else { return }
        await copy(value, target: .metadata(key: key))
    }

    /// Convenience: copy the loaded notes block if available. No-op
    /// if the model is not loaded or the entry has no notes. Posts an
    /// `.info` confirmation toast titled `"Notes copied"`.
    func copyNotes() async {
        guard case .loaded(let secret) = state,
              let notes = secret.metadata.notes,
              !notes.isEmpty
        else { return }
        await copy(notes, target: .notes)
    }

    // MARK: - Confirmation toast

    /// Post the per-copy confirmation toast. Severity `.info`
    /// because the action is non-destructive and acknowledgment-
    /// only. Title is `"<Label> copied"`; message is `"Auto-clears
    /// in <N>s"`. The toast NEVER contains the copied value — see
    /// the `.ai/decisions.md` ToastCenter contract.
    private func postCopyConfirmationToast(
        target: CopyTarget,
        delay: Duration
    ) {
        let seconds = Int(delay.components.seconds)
        let toast = Toast(
            severity: .info,
            title: "\(target.toastLabel) copied",
            message: "Auto-clears in \(seconds)s"
        )
        appState.toastCenter.post(toast)
    }

    // MARK: - Settings

    /// Sample the current clipboard auto-clear delay from
    /// ``SettingsStoring`` on every copy call.
    ///
    /// Falls back to ``SettingsKeys/defaultClipboardClearDelaySeconds``
    /// when the key is unset and clamps the persisted value into
    /// ``SettingsKeys/clipboardClearDelayBounds`` so a stale or
    /// out-of-range entry cannot produce a useless 0-second window or
    /// a runaway multi-hour delay.
    private func currentClipboardClearDelay() -> Duration {
        let raw = environment.settings
            .value(for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
            ?? SettingsKeys.defaultClipboardClearDelaySeconds
        let bounds = SettingsKeys.clipboardClearDelayBounds
        let clamped = min(max(raw, bounds.lowerBound), bounds.upperBound)
        return .seconds(clamped)
    }

    // MARK: - StoreChange subscription (Phase H.1)

    /// Subscribe to `passManager.changes` and reconcile detail-side
    /// state against events targeting the currently-displayed entry.
    ///
    /// Reaction policy:
    ///
    /// - `.updated(path)` — if `path == appState.selectedEntryID`,
    ///   re-fetch the secret via the existing selection-change
    ///   pipeline so the UI reflects the rewritten body (e.g. after
    ///   `pass generate --in-place` repopulates metadata).
    /// - `.removed(path)` — if `path == appState.selectedEntryID`,
    ///   clear the loaded secret. The list-side handler clears
    ///   `selectedEntryID` itself; this branch covers the case where
    ///   the detail model is still showing a body whose underlying
    ///   entry vanished.
    /// - `.moved(from, to)` — if `from == appState.selectedEntryID`,
    ///   re-fetch under the new path. The list-side handler updates
    ///   `selectedEntryID` to `to` (which would normally trigger
    ///   ``handleSelectionChange(_:)`` via the view's `.onChange`),
    ///   but we also drive the load explicitly to guarantee the
    ///   detail view converges even in tests / non-view contexts.
    /// - `.inserted`, `.bulk` — no detail-side reaction.
    ///
    /// Intended to be driven by the hosting view's `.task { await
    /// model.observeChanges() }` so the subscription's lifetime
    /// matches the view: SwiftUI cancels the surrounding task on
    /// disappear, the `for await` loop sees the cancellation and
    /// exits cleanly. Calling this method while a subscription is
    /// already active is a no-op.
    func observeChanges() async {
        guard changeSubscriptionTask == nil else { return }

        let stream = environment.passManager.changes

        let task = Task { [weak self] in
            for await event in stream {
                if Task.isCancelled { return }
                guard let self else { return }
                self.handle(event)
            }
        }
        changeSubscriptionTask = task

        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }

        changeSubscriptionTask = nil
    }

    /// Cancel the active changes subscription (if any). Idempotent.
    func stop() {
        changeSubscriptionTask?.cancel()
        changeSubscriptionTask = nil
    }

    /// React to a single `StoreChange` against the currently-
    /// displayed entry. See ``observeChanges()`` for the full rule
    /// table.
    private func handle(_ event: StoreChange) {
        let current = appState.router.selectedEntryID

        switch event {
        case .updated(let path):
            guard let current, current == path else { return }
            // Re-fetch via the existing selection pipeline. Passing
            // the same id cancels the prior task (idempotent here:
            // there is no prior in-flight load for the same id) and
            // schedules a fresh `pass.show` for the (now updated)
            // body.
            handleSelectionChange(current)

        case .removed(let path):
            guard let current, current == path else { return }
            // The list-side handler clears `router.selectedEntryID`
            // independently; this branch deals with the detail-only
            // state. Cancel any in-flight load and reset to idle so
            // the UI stops showing a body whose entry no longer
            // exists.
            loadTask?.cancel()
            loadTask = nil
            generation &+= 1
            isPasswordRevealed = false
            self.state = .idle

        case .moved(let from, let to):
            guard let current, current == from else { return }
            // Drive the load explicitly under the new path. In a
            // running app the list-side handler also updates
            // `selectedEntryID` to `to`, which fires the view's
            // `.onChange` and calls `handleSelectionChange(to)`;
            // doing it here too is idempotent (the second call
            // cancels the first in-flight task and starts a fresh
            // one against the same id, which is cheap and converges
            // to the same final state).
            handleSelectionChange(to)

        case .inserted, .bulk:
            // No detail-side reaction.
            return
        }
    }

    // MARK: - Private

    /// Apply `newState` only if `taskGeneration` is still current. The
    /// `onlyIfCurrent` escape hatch is used by cancellation paths that
    /// must always reset to idle even if a newer load has started —
    /// in practice the newer load has already overwritten `state`, so
    /// the gate stays meaningful and we keep the default `true`.
    private func apply(
        _ newState: State,
        generation taskGeneration: UInt64,
        onlyIfCurrent: Bool = true
    ) {
        guard !onlyIfCurrent || taskGeneration == self.generation else { return }
        self.state = newState
    }
}
