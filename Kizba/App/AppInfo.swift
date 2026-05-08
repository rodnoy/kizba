// AppInfo.swift
// Simple helper exposing app version and build metadata
// Read-only, safe accessors that avoid force-unwrapping.

import Foundation

/// Small helper to surface app bundle version/build strings.
/// Kept minimal and safe: no force-unwraps.
public enum AppInfo {
    public static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    public static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
