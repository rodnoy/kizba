//
//  SettingsModel.swift
//  Kizba
//
//  Presentation-layer view model for the Settings page.
//

import Foundation
import Observation

@MainActor
@Observable
public final class SettingsModel {

    // MARK: - Published properties consumed by the Settings view

    public var storePathOverride: String?
    public var passBinaryOverride: String?
    public var gpgBinaryOverride: String?
    public var pinentryBinaryOverride: String?

    /// Non-optional clipboard clear delay. Defaults to 30 when the
    /// underlying store has no explicit value.
    public var clipboardClearDelaySeconds: Int
    /// When true, require biometric authentication for sensitive actions.
    public var touchIDForSensitiveActions: Bool
    /// Git operation timeout in seconds (pull, push).
    public var gitOperationTimeoutSeconds: Int
    public var showInMenuBar: Bool
    /// When true, the sidebar renders the Recents section. Persisted under
    /// ``SettingsKeys/showRecents``.
    public var showRecents: Bool
    /// When true, the sidebar renders the Favorites section. Persisted
    /// under ``SettingsKeys/showFavorites`` (MVP6 G.1). Symmetric with
    /// ``showRecents``.
    public var showFavorites: Bool
    /// Soft cap on the number of recently-viewed entries surfaced in the
    /// sidebar Recents section. Clamped to ``SettingsKeys/recentsLimitBounds``
    /// on persist by the settings store, and propagated to the actor store via
    /// ``RecentEntriesStoring/setMaxCount(_:)`` on save.
    public var recentsLimit: Int

    /// Toggles while a discovery operation is in-flight.
    public private(set) var isDetectingBinaries: Bool = false

    // MARK: - Dirty-tracking / save state (MVP6 Phase B.2)

    /// Three-state machine driving the inline "Saving…" / "Saved" footer
    /// feedback. Transitions: `.idle → .saving → .saved → .idle` (the last
    /// hop fires after ``savedFlashDuration`` elapses).
    public enum SaveState: Equatable {
        case idle
        case saving
        case saved
    }

    // MARK: - Biometric toggle (MVP6 Phase D.1)

    /// Failure modes surfaced by ``requestToggleBiometric(_:)``. Maps the
    /// neutral ``BiometricResult`` / ``BiometricAvailability`` shapes from
    /// the domain protocol into a single Result-friendly error so the UI
    /// (SecurityTab — MVP6 D.2) can render a single banner per case.
    ///
    /// `nonisolated` because the domain `BiometricUnavailableReason` /
    /// `BiometricFailureReason` enums (declared in the domain layer with
    /// `Sendable, Equatable`) carry nonisolated `Equatable` conformances;
    /// nesting a main-actor-isolated `Equatable` here would refuse to
    /// compose with them under Swift 6 `InferIsolatedConformances`.
    public nonisolated enum ToggleBiometricError: Error, Equatable {
        /// Biometric authentication is not currently available (no hardware,
        /// not enrolled, etc). The persisted value is unchanged.
        case unavailable(BiometricUnavailableReason)
        /// The user dismissed the OS biometric prompt. The persisted value
        /// is unchanged. Distinct from ``failed`` so the UI can stay quiet
        /// on explicit cancel (matches platform conventions).
        case cancelled
        /// Authentication attempt completed but did not succeed
        /// (wrong fingerprint, system cancel, etc).
        case failed(BiometricFailureReason)
    }

    /// Live snapshot of every editable field in this model. Excludes
    /// transient state (``isDetectingBinaries``, ``saveState``).
    ///
    /// IMPORTANT: keep in sync with the editable `SettingsModel` fields.
    /// Adding a new persisted field requires extending both ``currentSnapshot``
    /// and this struct, otherwise ``hasChanges`` will silently miss mutations.
    private struct SettingsSnapshot: Equatable {
        let clipboardClearDelaySeconds: Int
        let touchIDForSensitiveActions: Bool
        let gitOperationTimeoutSeconds: Int
        let showInMenuBar: Bool
        let showRecents: Bool
        let showFavorites: Bool
        let recentsLimit: Int
        // String? overrides: `nil` (no override) and `""` (explicit empty
        // override) are kept distinct on purpose so the dirty check matches
        // the user-visible distinction surfaced by ``bindingForOptional``.
        let storePathOverride: String?
        let passBinaryOverride: String?
        let gpgBinaryOverride: String?
        let pinentryBinaryOverride: String?
    }

    private var currentSnapshot: SettingsSnapshot {
        SettingsSnapshot(
            clipboardClearDelaySeconds: clipboardClearDelaySeconds,
            touchIDForSensitiveActions: touchIDForSensitiveActions,
            gitOperationTimeoutSeconds: gitOperationTimeoutSeconds,
            showInMenuBar: showInMenuBar,
            showRecents: showRecents,
            showFavorites: showFavorites,
            recentsLimit: recentsLimit,
            storePathOverride: storePathOverride,
            passBinaryOverride: passBinaryOverride,
            gpgBinaryOverride: gpgBinaryOverride,
            pinentryBinaryOverride: pinentryBinaryOverride
        )
    }

    /// Snapshot captured at init and refreshed after every successful
    /// ``save()`` / ``resetToDefaults()``. ``hasChanges`` compares
    /// ``currentSnapshot`` against this baseline.
    private var initialSnapshot: SettingsSnapshot

    /// `true` when any tracked field diverges from the last persisted /
    /// reset baseline. Drives the Save button's enabled binding.
    public var hasChanges: Bool { currentSnapshot != initialSnapshot }

    /// Current persistence state. Observed by `SettingsView` to render the
    /// inline "Saving…" / "Saved" status text adjacent to Save.
    public var saveState: SaveState = .idle

    // MARK: - Dependencies

    private let settings: any SettingsStoring
    private let discovery: any BinaryLocating
    private let recentStore: any RecentEntriesStoring
    /// Optional biometric authenticator. `nil` in tests/previews that have
    /// no real authenticator wired — in that case
    /// ``requestToggleBiometric(_:)`` permits a disable without prompt
    /// because there is no real protection to defeat (MVP6 Phase D.1).
    private let biometricAuth: (any BiometricAuthenticating)?
    private let savedFlashDuration: Duration

    // MARK: - Init

    /// - Parameters:
    ///   - settings: persistent key-value store for user preferences.
    ///   - discovery: binary locator used by "Re-detect binaries".
    ///   - recentStore: Recents actor store. ``save()`` propagates the
    ///     in-memory ``recentsLimit`` to the actor via
    ///     ``RecentEntriesStoring/setMaxCount(_:)`` after persisting the
    ///     settings key, so observers see the new cap reflected in the
    ///     sidebar without an app restart (MVP6 Phase A).
    ///   - savedFlashDuration: how long ``saveState`` stays in `.saved`
    ///     before flipping back to `.idle`. Defaults to 1500 ms for
    ///     production; tests inject a much smaller value to keep the
    ///     suite fast.
    public init(
        settings: any SettingsStoring,
        discovery: any BinaryLocating,
        recentStore: any RecentEntriesStoring,
        biometricAuth: (any BiometricAuthenticating)? = nil,
        savedFlashDuration: Duration = .milliseconds(1500)
    ) {
        self.settings = settings
        self.discovery = discovery
        self.recentStore = recentStore
        self.biometricAuth = biometricAuth
        self.savedFlashDuration = savedFlashDuration

        // Read initial values from the store. Use SettingsKeys constants
        // as the single source of truth for key names.
        let storePathOverride = settings.value(for: SettingsKey<String>(SettingsKeys.storePathOverride))
        let passBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.passBinaryOverride))
        let gpgBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.gpgBinaryOverride))
        let pinentryBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.pinentryBinaryOverride))

        let clipboardClearDelaySeconds = settings.value(for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
            ?? SettingsKeys.defaultClipboardClearDelaySeconds
        let touchIDForSensitiveActions = settings.value(for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)) ?? false
        let gitOperationTimeoutSeconds = settings.value(for: SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds))
            ?? SettingsKeys.defaultGitOperationTimeoutSeconds
        let showInMenuBar = settings.value(for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
            ?? SettingsKeys.defaultShowInMenuBar
        let showRecents = settings.value(for: SettingsKey<Bool>(SettingsKeys.showRecents))
            ?? SettingsKeys.defaultShowRecents
        let showFavorites = settings.value(for: SettingsKey<Bool>(SettingsKeys.showFavorites))
            ?? SettingsKeys.defaultShowFavorites
        let recentsLimit = settings.value(for: SettingsKey<Int>(SettingsKeys.recentsLimit))
            ?? SettingsKeys.defaultRecentsLimit

        self.storePathOverride = storePathOverride
        self.passBinaryOverride = passBinaryOverride
        self.gpgBinaryOverride = gpgBinaryOverride
        self.pinentryBinaryOverride = pinentryBinaryOverride
        self.clipboardClearDelaySeconds = clipboardClearDelaySeconds
        self.touchIDForSensitiveActions = touchIDForSensitiveActions
        self.gitOperationTimeoutSeconds = gitOperationTimeoutSeconds
        self.showInMenuBar = showInMenuBar
        self.showRecents = showRecents
        self.showFavorites = showFavorites
        self.recentsLimit = recentsLimit

        // Seed the dirty-tracking baseline so a freshly-loaded model
        // reports `hasChanges == false`.
        self.initialSnapshot = SettingsSnapshot(
            clipboardClearDelaySeconds: clipboardClearDelaySeconds,
            touchIDForSensitiveActions: touchIDForSensitiveActions,
            gitOperationTimeoutSeconds: gitOperationTimeoutSeconds,
            showInMenuBar: showInMenuBar,
            showRecents: showRecents,
            showFavorites: showFavorites,
            recentsLimit: recentsLimit,
            storePathOverride: storePathOverride,
            passBinaryOverride: passBinaryOverride,
            gpgBinaryOverride: gpgBinaryOverride,
            pinentryBinaryOverride: pinentryBinaryOverride
        )
    }

    // MARK: - Actions

    /// Persist current in-memory values into the provided settings store.
    ///
    /// No-op when ``hasChanges`` is `false`: avoids redundant disk writes
    /// and keeps ``saveState`` at `.idle` (the UI footer stays clean).
    ///
    /// Flow:
    /// 1. `.saving` flips on.
    /// 2. Sync settings writes complete.
    /// 3. `recentStore.setMaxCount(_:)` is awaited so the actor store has
    ///    truly absorbed the new cap before we declare success (no
    ///    deadlock risk: we are already off the actor and the store hop
    ///    is one-shot).
    /// 4. Baseline snapshot rebuilt → ``hasChanges`` returns `false`.
    /// 5. `.saved` flashes for ``savedFlashDuration``, then `.idle`.
    ///    A capture-check guards against another save racing in: only
    ///    the most recent `.saved` window gets cleared.
    public func save() async {
        guard hasChanges else { return }

        saveState = .saving

        settings.set(storePathOverride, for: SettingsKey<String>(SettingsKeys.storePathOverride))
        settings.set(passBinaryOverride, for: SettingsKey<String>(SettingsKeys.passBinaryOverride))
        settings.set(gpgBinaryOverride, for: SettingsKey<String>(SettingsKeys.gpgBinaryOverride))
        settings.set(pinentryBinaryOverride, for: SettingsKey<String>(SettingsKeys.pinentryBinaryOverride))
        settings.set(clipboardClearDelaySeconds, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        settings.set(touchIDForSensitiveActions, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
        settings.set(gitOperationTimeoutSeconds, for: SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds))
        settings.set(showInMenuBar, for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
        settings.set(showRecents, for: SettingsKey<Bool>(SettingsKeys.showRecents))
        settings.set(showFavorites, for: SettingsKey<Bool>(SettingsKeys.showFavorites))
        // `UserDefaultsSettingsStore` clamps `recentsLimit` writes to
        // ``SettingsKeys/recentsLimitBounds``, so the store is the single
        // source of truth for the clamp; this avoids double-clamping here.
        settings.set(recentsLimit, for: SettingsKey<Int>(SettingsKeys.recentsLimit))

        // Re-read the persisted (and possibly clamped) value to keep the
        // in-memory model and the actor store in sync after a save round-trip.
        let persistedLimit = settings.value(for: SettingsKey<Int>(SettingsKeys.recentsLimit))
            ?? SettingsKeys.defaultRecentsLimit
        recentsLimit = persistedLimit

        // Propagate the new cap to the Recents actor store. Awaited inline
        // (we are async on the MainActor); the actor hop is one-shot and
        // cannot re-enter us, so there is no deadlock risk.
        await recentStore.setMaxCount(persistedLimit)

        // Rebuild the dirty baseline AFTER persistence so `hasChanges`
        // flips back to false in lockstep with the on-disk state.
        initialSnapshot = currentSnapshot

        saveState = .saved
        try? await Task.sleep(for: savedFlashDuration)
        // Only clear if no newer save() has taken over in the meantime.
        if saveState == .saved {
            saveState = .idle
        }
    }

    /// Remove override entries and restore the clipboard delay to the
    /// default value.
    public func resetToDefaults() {
        // Remove raw override keys.
        settings.removeValue(forKey: SettingsKeys.storePathOverride)
        settings.removeValue(forKey: SettingsKeys.passBinaryOverride)
        settings.removeValue(forKey: SettingsKeys.gpgBinaryOverride)
        settings.removeValue(forKey: SettingsKeys.pinentryBinaryOverride)

        // Reset clipboard delay to default and persist.
        clipboardClearDelaySeconds = SettingsKeys.defaultClipboardClearDelaySeconds
        settings.set(clipboardClearDelaySeconds, for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
        // Reset biometric reveal setting to default (false).
        touchIDForSensitiveActions = false
        settings.removeValue(forKey: SettingsKeys.touchIDForSensitiveActions)
        gitOperationTimeoutSeconds = SettingsKeys.defaultGitOperationTimeoutSeconds
        settings.set(gitOperationTimeoutSeconds, for: SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds))
        showInMenuBar = SettingsKeys.defaultShowInMenuBar
        settings.set(showInMenuBar, for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))

        // Reflect cleared overrides in-memory as well.
        storePathOverride = nil
        passBinaryOverride = nil
        gpgBinaryOverride = nil
        pinentryBinaryOverride = nil

        // Rebuild the dirty baseline so the Save button immediately
        // returns to the disabled state after a reset.
        initialSnapshot = currentSnapshot
    }

    /// Ask the discovery service to re-detect binaries. Toggles
    /// `isDetectingBinaries` for the duration of the operation.
    public func reDetectBinaries() async {
        isDetectingBinaries = true
        defer { isDetectingBinaries = false }
        await discovery.reDetect()
    }

    // MARK: - Biometric toggle (MVP6 Phase D.1)

    /// Current biometric availability reported by the injected
    /// authenticator. When no authenticator is wired (tests/preview),
    /// reports `.unavailable(.hardwareUnavailable)` so UI gating
    /// (SecurityTab — D.2) treats the row as disabled rather than
    /// pretending biometrics work.
    public var biometricAvailability: BiometricAvailability {
        biometricAuth?.isAvailable() ?? .unavailable(.hardwareUnavailable)
    }

    /// Request a flip of ``touchIDForSensitiveActions`` with the platform's
    /// "enable freely, prompt-to-disable" semantics (see
    /// `.ai/decisions.md` — MVP6.D.1):
    ///
    /// - Enabling (`desired == true`): persists immediately without a
    ///   biometric prompt. Matches the macOS FileVault / Touch ID
    ///   settings pane UX — turning protection ON is low-stakes.
    /// - Disabling (`desired == false`) with an authenticator wired:
    ///   requires a successful `authenticate(reason:)` call. On
    ///   cancel/failure the persisted value is unchanged and the UI
    ///   surfaces the failure via the returned ``ToggleBiometricError``.
    /// - Disabling with NO authenticator wired (tests/preview): permitted
    ///   without prompt, because there is no real protection to defeat.
    ///
    /// On every successful persist the dirty-tracking baseline
    /// (``initialSnapshot``) is refreshed so the B.2 `hasChanges` flag
    /// does not falsely mark the row dirty — this method writes to the
    /// store directly, bypassing ``save()``.
    public func requestToggleBiometric(_ desired: Bool) async -> Result<Void, ToggleBiometricError> {
        // Enable path: no prompt, persist immediately. Matches FileVault /
        // Touch ID system settings UX.
        if desired {
            touchIDForSensitiveActions = true
            settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
            // Refresh snapshot so hasChanges (B.2 dirty tracking) reflects
            // only un-persisted UI mutations — this write bypasses save().
            initialSnapshot = currentSnapshot
            return .success(())
        }

        // Disable path: no authenticator wired (tests/preview). There is no
        // real protection to defeat, so let the disable through.
        guard let auth = biometricAuth else {
            touchIDForSensitiveActions = false
            settings.set(false, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
            initialSnapshot = currentSnapshot
            return .success(())
        }

        // Disable path: real authenticator. Check availability first to
        // avoid presenting an OS dialog we know will fail.
        switch auth.isAvailable() {
        case .unavailable(let reason):
            return .failure(.unavailable(reason))
        case .available:
            break
        }

        // Present the biometric prompt; map the neutral result back into
        // our Result-friendly error shape.
        switch await auth.authenticate(reason: "Confirm to disable Touch ID protection") {
        case .success:
            touchIDForSensitiveActions = false
            settings.set(false, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
            initialSnapshot = currentSnapshot
            return .success(())
        case .cancelled:
            return .failure(.cancelled)
        case .failed(let reason):
            return .failure(.failed(reason))
        }
    }
}
