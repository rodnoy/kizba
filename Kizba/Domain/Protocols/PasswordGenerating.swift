//
//  PasswordGenerating.swift
//  Kizba
//
//  Pure password-generation surface used by Phase F's "New entry" form
//  to preview a candidate password before it is committed to the store.
//
//  In-place regeneration of an existing entry uses `pass generate
//  --in-place` instead (atomic, preserves metadata) — see Phase G. The
//  preview path needs a generator that does NOT touch the store, so we
//  ship our own pure Swift implementation here.
//
//  Per `.ai/decisions.md`:
//  - `LivePasswordGenerator` uses `SystemRandomNumberGenerator`
//    (CSPRNG-backed; on Darwin = arc4random_buf).
//  - Charsets match `pass generate` defaults.
//  - Rejection sampling against modulo bias is delegated to the
//    standard library's `Int.random(in:)` (it implements rejection
//    sampling internally on Darwin).
//

import Foundation

/// Errors thrown by ``PasswordGenerating`` implementations.
///
/// Only the lower bound is enforced at the protocol level. Upper bounds
/// (e.g. UI sliders capped at 128) belong in the calling form model so
/// that the protocol stays pure and reusable.
public enum PasswordGenerationError: Error, Equatable, Sendable {

    /// Requested length is `<= 0`. Carries the requested value to give
    /// callers diagnostic context without losing it to a generic error.
    case invalidLength(_ requested: Int)
}

/// Generates a fresh password of the requested length and charset.
///
/// `Sendable` so a single instance can flow across actor boundaries
/// (form model on `@MainActor`, infrastructure on background tasks).
public protocol PasswordGenerating: Sendable {

    /// Produce a new password.
    ///
    /// - Parameters:
    ///   - length: Number of characters in the returned password. Must
    ///     be `>= 1`; otherwise ``PasswordGenerationError/invalidLength(_:)``
    ///     is thrown.
    ///   - includeSymbols: When `true`, include `pass generate`'s
    ///     default ASCII symbol set in addition to `[A-Za-z0-9]`.
    /// - Returns: A freshly generated password. Never logged.
    /// - Throws: ``PasswordGenerationError`` for invalid input.
    func generate(length: Int, includeSymbols: Bool) throws -> String
}
