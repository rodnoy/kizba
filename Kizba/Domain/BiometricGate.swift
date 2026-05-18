//
//  BiometricGate.swift
//  Kizba
//
//  Reusable Touch ID gate for sensitive actions.
//

import Foundation

@MainActor
public struct BiometricGate: Sendable {
    public static let sensitiveMetadataKeys: Set<String> = [
        "password", "pin", "token", "secret", "otpauth", "key"
    ]

    public let auth: (any BiometricAuthenticating)?
    public let settings: any SettingsStoring
    public let policyKey: SettingsKey<Bool>

    public init(
        auth: (any BiometricAuthenticating)?,
        settings: any SettingsStoring,
        policyKey: SettingsKey<Bool>
    ) {
        self.auth = auth
        self.settings = settings
        self.policyKey = policyKey
    }

    /// Returns `true` if the gated action may proceed.
    ///
    /// - Returns `true` immediately when policy is off, authenticator is nil,
    ///   or biometrics report `.unavailable`.
    /// - Returns `true` on `.success`, `false` on `.cancelled`/`.failed`.
    public func run(reason: String) async -> Bool {
        let enabled = settings.value(for: policyKey) ?? false
        guard enabled else { return true }

        guard let auth else { return true }

        switch auth.isAvailable() {
        case .unavailable:
            return true
        case .available:
            let result = await auth.authenticate(reason: reason)
            switch result {
            case .success:
                return true
            case .cancelled, .failed:
                return false
            }
        }
    }

    /// Convenience helper for metadata copy gating.
    ///
    /// Returns `true` iff `key` (case-insensitive) is in
    /// `sensitiveMetadataKeys`.
    public static func isSensitiveMetadataKey(_ key: String) -> Bool {
        sensitiveMetadataKeys.contains(key.lowercased())
    }
}
