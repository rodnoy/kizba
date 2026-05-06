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

    /// Copy a single field's value to the system pasteboard with
    /// token-checked auto-clear.
    ///
    /// - Parameters:
    ///   - value: Verbatim string written to the pasteboard. Per
    ///     `.ai/decisions.md`, never composed with the field's key.
    ///   - clearAfterSeconds: Delay before the auto-clear attempt.
    ///     Defaults to 30s — the documented MVP-1 default; Phase 8
    ///     wires the user-configurable override.
    func copy(_ value: String, clearAfterSeconds seconds: Int = 30) async {
        let delay = Duration.seconds(max(0, seconds))
        await environment.clipboard.copy(value, clearAfter: delay)
    }

    /// Convenience: copy the loaded password if available. No-op if
    /// the model is not in ``State/loaded(_:)``.
    func copyPassword(clearAfterSeconds seconds: Int = 30) async {
        guard case .loaded(let secret) = state else { return }
        await copy(secret.password, clearAfterSeconds: seconds)
    }

    /// Convenience: copy the first metadata value matching `key`.
    /// No-op if the model is not loaded or the key is absent.
    func copyMetadata(forKey key: String, clearAfterSeconds seconds: Int = 30) async {
        guard case .loaded(let secret) = state,
              let value = secret.metadata.firstValue(for: key)
        else { return }
        await copy(value, clearAfterSeconds: seconds)
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
