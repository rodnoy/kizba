// FakeBiometricAuthenticator.swift
// KizbaTests
//
// Deterministic test double for BiometricAuthenticating. Never
// touches LocalAuthentication. Tests control availability and the
// next authenticate result, and may assert against the recorded
// `authenticate(reason:)` invocation history.
//
// `@unchecked Sendable` is required because the fixture holds
// mutable state read & mutated from both XCTest's MainActor context
// and the implicitly nonisolated `authenticate(reason:)` async hop.
// All access is serialised through an NSLock; production
// authenticators are stateless or actor-isolated and do not need
// this construction.

import Foundation
@testable import Kizba

final class FakeBiometricAuthenticator: BiometricAuthenticating, @unchecked Sendable {
    private let lock = NSLock()

    private var _availability: BiometricAvailability
    private var _nextResult: BiometricResult
    private var _authenticateCalls: [String] = []

    init(
        availability: BiometricAvailability = .available,
        nextResult: BiometricResult = .success
    ) {
        self._availability = availability
        self._nextResult = nextResult
    }

    // MARK: - Configurable knobs (thread-safe)

    var availability: BiometricAvailability {
        get { lock.lock(); defer { lock.unlock() }; return _availability }
        set { lock.lock(); _availability = newValue; lock.unlock() }
    }

    var nextResult: BiometricResult {
        get { lock.lock(); defer { lock.unlock() }; return _nextResult }
        set { lock.lock(); _nextResult = newValue; lock.unlock() }
    }

    // MARK: - Recorded interactions

    /// Every `reason` string passed to `authenticate(reason:)` in
    /// invocation order. Tests assert both the count (was the prompt
    /// shown?) and the wording (does the model pass a sensible
    /// localised string?).
    var authenticateCalls: [String] {
        lock.lock(); defer { lock.unlock() }; return _authenticateCalls
    }

    /// Convenience accessor preserved for older tests that only care
    /// about the most recent prompt reason.
    var lastReason: String? {
        lock.lock(); defer { lock.unlock() }; return _authenticateCalls.last
    }

    // MARK: - BiometricAuthenticating

    func isAvailable() -> BiometricAvailability {
        availability
    }

    func authenticate(reason: String) async -> BiometricResult {
        // `NSLock.withLock` is a synchronous closure — it never suspends,
        // so the "lock unavailable from async contexts" diagnostic Swift
        // 6 raises on bare `lock()`/`unlock()` calls does not apply.
        lock.withLock {
            _authenticateCalls.append(reason)
            return _nextResult
        }
    }
}
