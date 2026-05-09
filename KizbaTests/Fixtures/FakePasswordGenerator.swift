//
//  FakePasswordGenerator.swift
//  KizbaTests
//
//  Deterministic ``PasswordGenerating`` test double. Records every
//  call (length, includeSymbols) and replays a programmed script of
//  passwords in FIFO order. When the script is exhausted, falls back
//  to a deterministic single-character padding so callers that do not
//  pre-script are still served reproducible output.
//
//  Concurrency: `final class` (mutable state) marked
//  `@unchecked Sendable` via an internal `NSLock`, mirroring
//  ``FakeShellRunner`` and the rest of the fixtures. Required because
//  ``PasswordGenerating`` is itself `Sendable`.
//

import Foundation
@testable import Kizba

/// Deterministic ``PasswordGenerating`` test double.
final class FakePasswordGenerator: PasswordGenerating, @unchecked Sendable {

    /// Snapshot of one `generate(...)` call as observed by the fake.
    struct Call: Sendable, Equatable {
        let length: Int
        let includeSymbols: Bool
    }

    private let lock = NSLock()
    private var script: [String]
    private var calls: [Call] = []

    /// Initialise with an optional FIFO script of pre-baked passwords.
    init(script: [String] = []) {
        self.script = script
    }

    /// Append a single scripted password to the queue.
    func push(_ password: String) {
        lock.lock(); defer { lock.unlock() }
        script.append(password)
    }

    /// All recorded calls, in order.
    var allCalls: [Call] {
        lock.lock(); defer { lock.unlock() }
        return calls
    }

    /// Most recent recorded call, if any.
    var lastCall: Call? {
        lock.lock(); defer { lock.unlock() }
        return calls.last
    }

    // MARK: - PasswordGenerating

    func generate(length: Int, includeSymbols: Bool) throws -> String {
        lock.lock(); defer { lock.unlock() }
        calls.append(Call(length: length, includeSymbols: includeSymbols))

        if length <= 0 {
            throw PasswordGenerationError.invalidLength(length)
        }

        if !script.isEmpty {
            return script.removeFirst()
        }

        // Deterministic fallback: a string of `x` (no symbols) or `y`
        // (symbols) of the requested length. Stable across runs and
        // distinct enough to assert on `includeSymbols` propagation.
        let filler: Character = includeSymbols ? "y" : "x"
        return String(repeating: filler, count: length)
    }
}
