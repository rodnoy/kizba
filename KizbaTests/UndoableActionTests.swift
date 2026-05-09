//
//  UndoableActionTests.swift
//  KizbaTests
//
//  Phase G.1 — minimum-viable coverage for the value type backing
//  ``ActionHistory``. Each case must construct without crashing,
//  must remain ``Sendable``-only, and must NOT acquire ``Codable`` /
//  ``CustomStringConvertible`` conformances by accident — the same
//  security non-conformances asserted on ``PassSecret`` apply here
//  because ``UndoableAction`` carries password material.
//

import XCTest
@testable import Kizba

final class UndoableActionTests: XCTestCase {

    // MARK: - Construction

    func testDeleteCase_constructsWithPathAndSecret() {
        let action: UndoableAction = .delete(
            path: "personal/email/gmail",
            secret: PassSecret(password: "p")
        )
        guard case .delete(let path, let secret) = action else {
            return XCTFail("expected .delete, got \(action)")
        }
        XCTAssertEqual(path, "personal/email/gmail")
        XCTAssertEqual(secret.password, "p")
    }

    func testMoveCase_constructsWithFromAndTo() {
        let action: UndoableAction = .move(from: "old/path", to: "new/path")
        guard case .move(let from, let to) = action else {
            return XCTFail("expected .move, got \(action)")
        }
        XCTAssertEqual(from, "old/path")
        XCTAssertEqual(to, "new/path")
    }

    func testInPlaceGenerateCase_constructsWithPathAndPreviousSecret() {
        let prior = PassSecret(
            password: "old-password",
            metadata: PassMetadata(fields: [.init(key: "user", value: "jane")])
        )
        let action: UndoableAction = .inPlaceGenerate(
            path: "work/aws/root",
            previousSecret: prior
        )
        guard case .inPlaceGenerate(let path, let previousSecret) = action else {
            return XCTFail("expected .inPlaceGenerate, got \(action)")
        }
        XCTAssertEqual(path, "work/aws/root")
        XCTAssertEqual(previousSecret, prior)
    }

    // MARK: - Security non-conformances

    /// ``UndoableAction`` carries ``PassSecret`` payloads. Acquiring
    /// ``Encodable`` / ``Decodable`` would defeat the on-disk-leak
    /// discipline asserted on ``PassSecret``.
    func testIsNotCodable() {
        XCTAssertFalse((UndoableAction.self as Any) is Encodable.Type)
        XCTAssertFalse((UndoableAction.self as Any) is Decodable.Type)
    }

    /// Same posture as ``PassSecret`` — no `description` /
    /// `debugDescription` would expose secret material via a stray
    /// `"\(action)"` interpolation.
    func testIsNotCustomStringConvertible() {
        XCTAssertFalse((UndoableAction.self as Any) is CustomStringConvertible.Type)
        XCTAssertFalse((UndoableAction.self as Any) is CustomDebugStringConvertible.Type)
    }

    // MARK: - Sendable conformance compiles

    /// Compile-time check: a generic helper that only accepts
    /// ``Sendable`` proves the conformance is in place. Runtime
    /// behaviour is irrelevant — the assertion is that this method
    /// type-checks.
    func testIsSendable() {
        func requireSendable<T: Sendable>(_ value: T) {}
        requireSendable(UndoableAction.move(from: "a", to: "b"))
        requireSendable(UndoableAction.delete(path: "x", secret: PassSecret(password: "p")))
    }
}
