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

    /// Toggles while a discovery operation is in-flight.
    public private(set) var isDetectingBinaries: Bool = false

    // MARK: - Dependencies

    private let settings: any SettingsStoring
    private let discovery: any BinaryLocating

    // MARK: - Init

    public init(settings: any SettingsStoring, discovery: any BinaryLocating) {
        self.settings = settings
        self.discovery = discovery

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
