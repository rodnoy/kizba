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
    /// When true, require biometric authentication for each password
    /// reveal in the detail view.
    public var touchIDPerRevealEnabled: Bool
    /// Git operation timeout in seconds (pull, push).
    public var gitOperationTimeoutSeconds: Int
    public var showInMenuBar: Bool
    /// When true, the sidebar renders the Recents section. Persisted under
    /// ``SettingsKeys/showRecents``.
    public var showRecents: Bool
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

    /// Live snapshot of every editable field in this model. Excludes
    /// transient state (``isDetectingBinaries``, ``saveState``).
    ///
    /// IMPORTANT: keep in sync with the editable `SettingsModel` fields.
    /// Adding a new persisted field requires extending both ``currentSnapshot``
    /// and this struct, otherwise ``hasChanges`` will silently miss mutations.
    private struct SettingsSnapshot: Equatable {
        let clipboardClearDelaySeconds: Int
        let touchIDPerRevealEnabled: Bool
        let gitOperationTimeoutSeconds: Int
        let showInMenuBar: Bool
        let showRecents: Bool
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
            touchIDPerRevealEnabled: touchIDPerRevealEnabled,
            gitOperationTimeoutSeconds: gitOperationTimeoutSeconds,
            showInMenuBar: showInMenuBar,
            showRecents: showRecents,
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
        savedFlashDuration: Duration = .milliseconds(1500)
    ) {
        self.settings = settings
        self.discovery = discovery
        self.recentStore = recentStore
        self.savedFlashDuration = savedFlashDuration

        // Read initial values from the store. Use SettingsKeys constants
        // as the single source of truth for key names.
        let storePathOverride = settings.value(for: SettingsKey<String>(SettingsKeys.storePathOverride))
        let passBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.passBinaryOverride))
        let gpgBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.gpgBinaryOverride))
        let pinentryBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.pinentryBinaryOverride))

        let clipboardClearDelaySeconds = settings.value(for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
            ?? SettingsKeys.defaultClipboardClearDelaySeconds
        let touchIDPerRevealEnabled = settings.value(for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)) ?? false
        let gitOperationTimeoutSeconds = settings.value(for: SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds))
            ?? SettingsKeys.defaultGitOperationTimeoutSeconds
        let showInMenuBar = settings.value(for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
            ?? SettingsKeys.defaultShowInMenuBar
        let showRecents = settings.value(for: SettingsKey<Bool>(SettingsKeys.showRecents))
            ?? SettingsKeys.defaultShowRecents
        let recentsLimit = settings.value(for: SettingsKey<Int>(SettingsKeys.recentsLimit))
            ?? SettingsKeys.defaultRecentsLimit

        self.storePathOverride = storePathOverride
        self.passBinaryOverride = passBinaryOverride
        self.gpgBinaryOverride = gpgBinaryOverride
        self.pinentryBinaryOverride = pinentryBinaryOverride
        self.clipboardClearDelaySeconds = clipboardClearDelaySeconds
        self.touchIDPerRevealEnabled = touchIDPerRevealEnabled
        self.gitOperationTimeoutSeconds = gitOperationTimeoutSeconds
        self.showInMenuBar = showInMenuBar
        self.showRecents = showRecents
        self.recentsLimit = recentsLimit

        // Seed the dirty-tracking baseline so a freshly-loaded model
        // reports `hasChanges == false`.
        self.initialSnapshot = SettingsSnapshot(
            clipboardClearDelaySeconds: clipboardClearDelaySeconds,
            touchIDPerRevealEnabled: touchIDPerRevealEnabled,
            gitOperationTimeoutSeconds: gitOperationTimeoutSeconds,
            showInMenuBar: showInMenuBar,
            showRecents: showRecents,
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
        settings.set(touchIDPerRevealEnabled, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        settings.set(gitOperationTimeoutSeconds, for: SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds))
        settings.set(showInMenuBar, for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
        settings.set(showRecents, for: SettingsKey<Bool>(SettingsKeys.showRecents))
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
        touchIDPerRevealEnabled = false
        settings.removeValue(forKey: SettingsKeys.touchIDPerRevealEnabled)
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
}
