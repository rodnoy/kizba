// BiometricAuthenticating.swift
// Kizba
//
// Public domain protocol and supporting enums describing biometric
// availability and authentication results. This file intentionally
// does not import LocalAuthentication to keep the domain layer free of
// platform coupling; infrastructure implementations may bridge to
// LocalAuthentication internally.

import Foundation

// MARK: - Availability

/// Reasons why biometric authentication may be unavailable on the
/// current device. Kept intentionally minimal and backend-agnostic.
///
/// `nonisolated` because the target's `default-isolation=MainActor`
/// would otherwise pin synthesized `Equatable` to MainActor, breaking
/// composition with non-MainActor consumers (e.g. nested in
/// `nonisolated` error enums) under Swift 6
/// `InferIsolatedConformances`. Domain protocol types must stay
/// actor-neutral by contract.
public nonisolated enum BiometricUnavailableReason: Sendable, Equatable {
    case notEnrolled
    case hardwareUnavailable
    case passcodeNotSet
    case userDisabled
    case unknown
}

/// Represents whether biometric authentication is available or not.
public nonisolated enum BiometricAvailability: Sendable, Equatable {
    case available
    case unavailable(BiometricUnavailableReason)
}

// MARK: - Failure / Result

/// Failure reasons for a biometric authentication attempt. Mapped by
/// infrastructure from platform errors into this neutral shape.
public nonisolated enum BiometricFailureReason: Sendable, Equatable {
    case userFailed
    case systemCancel
    case appCancel
    case invalidContext
    case unknown
}

/// Result of an authentication attempt.
public nonisolated enum BiometricResult: Sendable, Equatable {
    /// Authentication succeeded and the caller may proceed.
    case success
    /// The user cancelled the prompt (explicit cancel / tapped cancel).
    case cancelled
    /// Authentication failed for the given failure reason.
    case failed(BiometricFailureReason)
}

// MARK: - Protocol

/// Pure domain protocol describing biometric authentication. Implement
///ations live in `Infrastructure/` and may bridge to LocalAuthentication.
/// Conforming types must be `Sendable` so they can be held by actors.
public protocol BiometricAuthenticating: Sendable {
    /// Synchronously report whether biometric authentication is
    /// available on this device and if not, why.
    func isAvailable() -> BiometricAvailability

    /// Present the biometric prompt to the user with the provided
    /// reason text and return a neutral result. This method is
    /// intentionally non-throwing; implementations map errors into
    /// `BiometricResult.failed(..)`.
    func authenticate(reason: String) async -> BiometricResult
}
