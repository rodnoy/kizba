// FakeBiometricAuthenticator.swift
// KizbaTests
//
// Deterministic test double for BiometricAuthenticating. Never
// touches LocalAuthentication. Tests control availability and the
// next authenticate result.

import Foundation
@testable import Kizba

final class FakeBiometricAuthenticator: BiometricAuthenticating, @unchecked Sendable {
    var availability: BiometricAvailability = .available
    var nextResult: BiometricResult = .success
    private(set) var lastReason: String? = nil

    init(availability: BiometricAvailability = .available, nextResult: BiometricResult = .success) {
        self.availability = availability
        self.nextResult = nextResult
    }

    func isAvailable() -> BiometricAvailability {
        availability
    }

    func authenticate(reason: String) async -> BiometricResult {
        lastReason = reason
        return nextResult
    }
}
