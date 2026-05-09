//
//  PassManagingTestDefaults.swift
//  KizbaTests
//
//  Test-only default implementations for the MVP 2 write surface of
//  ``PassManaging`` and the ``changes`` ``AsyncStream``. Lets the
//  pre-Phase-E.5 read-only fakes scattered across the test target
//  (``StubPassManager``, ``NullPassManager``, ``ScriptedPassManager``,
//  ``FakePassManager``, ``InMemoryPassManager``, ``SlowPassManager``)
//  keep compiling without each one having to spell out four
//  `fatalError` stubs and an empty stream.
//
//  Behaviour:
//
//  - The four write methods raise ``XCTFail`` and throw a synthetic
//    ``PassError/writeFailed`` so any test that accidentally exercises
//    a write through a read-only fake fails loudly rather than
//    silently producing empty results.
//  - ``changes`` returns an empty stream that finishes immediately —
//    `for await` consumers see end-of-stream and move on.
//
//  Test fakes that DO want to exercise the write surface (notably the
//  Phase F+G form-model tests) override these defaults with their own
//  bespoke implementations.
//

import Foundation
import XCTest
@testable import Kizba

extension PassManaging {

    func insert(_ entry: PassEntry, secret: PassSecret, force: Bool) async throws -> PassEntry {
        XCTFail("PassManaging test-default insert(_:secret:force:) called on \(type(of: self)) — wire a real implementation if this fake needs writes.")
        throw PassError.writeFailed(reason: "test-default insert not implemented")
    }

    func generate(
        _ entry: PassEntry,
        length: Int,
        includeSymbols: Bool,
        force: Bool
    ) async throws -> PassSecret {
        XCTFail("PassManaging test-default generate(_:length:includeSymbols:force:) called on \(type(of: self)) — wire a real implementation if this fake needs writes.")
        throw PassError.writeFailed(reason: "test-default generate not implemented")
    }

    func remove(_ entry: PassEntry) async throws {
        XCTFail("PassManaging test-default remove(_:) called on \(type(of: self)) — wire a real implementation if this fake needs writes.")
        throw PassError.writeFailed(reason: "test-default remove not implemented")
    }

    func move(from: PassEntry, to newPath: String, force: Bool) async throws -> PassEntry {
        XCTFail("PassManaging test-default move(from:to:force:) called on \(type(of: self)) — wire a real implementation if this fake needs writes.")
        throw PassError.writeFailed(reason: "test-default move not implemented")
    }

    var changes: AsyncStream<StoreChange> {
        AsyncStream { continuation in
            // Finish immediately so consumers don't hang waiting on a
            // stream that will never emit. Tests that need real
            // `StoreChange` events override `changes` on their own fake.
            continuation.finish()
        }
    }
}
