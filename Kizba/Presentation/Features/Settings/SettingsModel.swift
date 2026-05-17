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

    // MARK: - Dependencies

    private let settings: any SettingsStoring
    private let discovery: any BinaryLocating
    private let recentStore: any RecentEntriesStoring

    // MARK: - Init

    /// - Parameters:
    ///   - settings: persistent key-value store for user preferences.
    ///   - discovery: binary locator used by "Re-detect binaries".
    ///   - recentStore: Recents actor store. ``save()`` propagates the
    ///     in-memory ``recentsLimit`` to the actor via
    ///     ``RecentEntriesStoring/setMaxCount(_:)`` after persisting the
    ///     settings key, so observers see the new cap reflected in the
    ///     sidebar without an app restart (MVP6 Phase A).
    public init(
        settings: any SettingsStoring,
        discovery: any BinaryLocating,
        recentStore: any RecentEntriesStoring
    ) {
        self.settings = settings
        self.discovery = discovery
        self.recentStore = recentStore

        // Read initial values from the store. Use SettingsKeys constants
        // as the single source of truth for key names.
        self.storePathOverride = settings.value(for: SettingsKey<String>(SettingsKeys.storePathOverride))
        self.passBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.passBinaryOverride))
        self.gpgBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.gpgBinaryOverride))
        self.pinentryBinaryOverride = settings.value(for: SettingsKey<String>(SettingsKeys.pinentryBinaryOverride))

        self.clipboardClearDelaySeconds = settings.value(for: SettingsKey<Int>(SettingsKeys.clipboardClearDelaySeconds))
            ?? SettingsKeys.defaultClipboardClearDelaySeconds
        self.touchIDPerRevealEnabled = settings.value(for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)) ?? false
        self.gitOperationTimeoutSeconds = settings.value(for: SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds))
            ?? SettingsKeys.defaultGitOperationTimeoutSeconds
        self.showInMenuBar = settings.value(for: SettingsKey<Bool>(SettingsKeys.showInMenuBar))
            ?? SettingsKeys.defaultShowInMenuBar
        self.showRecents = settings.value(for: SettingsKey<Bool>(SettingsKeys.showRecents))
            ?? SettingsKeys.defaultShowRecents
        self.recentsLimit = settings.value(for: SettingsKey<Int>(SettingsKeys.recentsLimit))
            ?? SettingsKeys.defaultRecentsLimit
    }

    // MARK: - Actions

    /// Persist current in-memory values into the provided settings store.
    public func save() {
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

        // Propagate the new cap to the Recents actor store so observers see
        // the updated sidebar list without an app restart. Persist first,
        // then signal — `setMaxCount` itself truncates and emits exactly
        // one `recentsChanged` event (see RecentEntriesStoring contract).
        Task { [recentStore, persistedLimit] in
            await recentStore.setMaxCount(persistedLimit)
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
    }

    /// Ask the discovery service to re-detect binaries. Toggles
    /// `isDetectingBinaries` for the duration of the operation.
    public func reDetectBinaries() async {
        isDetectingBinaries = true
        defer { isDetectingBinaries = false }
        await discovery.reDetect()
    }
}
