// LocalAuthBiometricAuthenticator.swift
// Kizba
//
// LA-backed implementation of BiometricAuthenticating. This class
// creates a fresh LAContext per call and maps platform errors into the
// domain enums. Mapping helpers are internal & static so tests can
// exercise the mapping without invoking system UI.

import Foundation
import LocalAuthentication

final class LocalAuthBiometricAuthenticator: BiometricAuthenticating, @unchecked Sendable {
    // No stored properties — LAContext instances are created per-call.

    /// Synchronously check whether biometric authentication is available
    /// on this device. A new `LAContext` is created for the check so
    /// callers need not worry about context lifecycle.
    func isAvailable() -> BiometricAvailability {
        let context = LAContext()
        var nsError: NSError?
        let can = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &nsError)
        if can {
            return .available
        } else {
            return .unavailable(Self.mapUnavailableReason(from: nsError))
        }
    }

    /// Present the biometric prompt with the provided reason and return
    /// a neutral BiometricResult. This method bridges the callback-based
    /// `evaluatePolicy` via a continuation. The continuation is resumed
    /// exactly once on all code paths.
    func authenticate(reason: String) async -> BiometricResult {
        let context = LAContext()

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume(returning: .success)
                    return
                }

                // If the user explicitly cancelled the prompt, report
                // the neutral `cancelled` result.
                if let laError = error as? LAError {
                    if laError.code == .userCancel {
                        continuation.resume(returning: .cancelled)
                        return
                    }
                    // Map other LAError codes to domain failure reasons.
                    let reason = Self.mapFailureReason(from: laError)
                    continuation.resume(returning: .failed(reason))
                    return
                }

                // Unknown error shape — return unknown failure.
                continuation.resume(returning: .failed(.unknown))
            }
        }
    }

    // MARK: - Mapping helpers

    /// Map an NSError (possibly from `canEvaluatePolicy`) into a
    /// BiometricUnavailableReason. Internal for testability.
    internal static nonisolated func mapUnavailableReason(from error: Error?) -> BiometricUnavailableReason {
        guard let ns = error as NSError? else {
            return .unknown
        }

        // LAError codes are represented by the LAError.errorDomain.
        if ns.domain == LAError.errorDomain {
            switch LAError.Code(rawValue: ns.code) {
            case .biometryNotEnrolled:
                return .notEnrolled
            case .biometryNotAvailable:
                return .hardwareUnavailable
            case .passcodeNotSet:
                return .passcodeNotSet
            case .biometryLockout:
                return .userDisabled
            default:
                return .unknown
            }
        }

        return .unknown
    }

    /// Map an LAError (or other Error) produced by `evaluatePolicy` into
    /// a BiometricFailureReason. Internal for testability.
    internal static nonisolated func mapFailureReason(from error: Error?) -> BiometricFailureReason {
        guard let la = error as? LAError else {
            return .unknown
        }

        switch la.code {
        case .authenticationFailed:
            return .userFailed
        case .systemCancel:
            return .systemCancel
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        default:
            return .unknown
        }
    }
}
