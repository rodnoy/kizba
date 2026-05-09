//
//  DomainModelsRefinementTests.swift
//  KizbaTests
//
//  Step 1.3 — refinement of domain unit tests. Adds edge-case coverage
//  for `PassEntry`, `PassMetadata`, `PassSecret` and `PassError` on top
//  of `DomainModelsTests.swift`. Tests are intentionally small,
//  deterministic and self-contained — no production-code changes are
//  required (and none are made).
//
//  Security invariants for `PassSecret` (NOT Codable, NOT
//  CustomStringConvertible) are already covered in
//  `PassSecretSecurityTests`; we deliberately do not re-test or relax
//  them here.
//

import XCTest
@testable import Kizba

// MARK: - PassEntry edge cases

final class PassEntryRefinementTests: XCTestCase {

    func testEmptyPathYieldsEmptyNameAndFolder() {
        let entry = PassEntry(path: "")
        XCTAssertEqual(entry.name, "")
        XCTAssertEqual(entry.folder, "")
        XCTAssertEqual(entry.id, "")
    }

    func testTrailingSlashIsTreatedAsEmptyName() {
        // The path-derivation rules slice on the *last* `/`; a trailing
        // slash therefore yields an empty `name` and the rest as
        // `folder`. We pin this behaviour so future refactors stay
        // intentional.
        let entry = PassEntry(path: "work/")
        XCTAssertEqual(entry.name, "")
        XCTAssertEqual(entry.folder, "work")
    }

    func testUnicodeAndSpacesInPath() {
        let entry = PassEntry(path: "личное/почта/Семейный счёт")
        XCTAssertEqual(entry.name, "Семейный счёт")
        XCTAssertEqual(entry.folder, "личное/почта")
    }

    func testHashableSemanticsInSet() {
        let a = PassEntry(path: "a/b")
        let b = PassEntry(path: "a/b")
        let c = PassEntry(path: "a/c")
        let set: Set<PassEntry> = [a, b, c]
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(PassEntry(path: "a/b")))
    }

    func testIdMatchesPathForIdentifiable() {
        let entry = PassEntry(path: "vault/root")
        XCTAssertEqual(entry.id, entry.path)
    }

    func testCodableJSONShapeIsStable() throws {
        // Lock down the on-wire JSON key so accidental renames during
        // refactors are caught here.
        let entry = PassEntry(path: "work/aws")
        let data = try JSONEncoder().encode(entry)
        let json = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        XCTAssertEqual(json["path"] as? String, "work/aws")
        XCTAssertEqual(json.keys.count, 1)
    }
}

// MARK: - PassMetadata edge cases

final class PassMetadataRefinementTests: XCTestCase {

    func testFirstValueIsCaseSensitive() {
        let meta = PassMetadata(fields: [
            .init(key: "URL", value: "upper"),
            .init(key: "url", value: "lower"),
        ])
        XCTAssertEqual(meta.firstValue(for: "url"), "lower")
        XCTAssertEqual(meta.firstValue(for: "URL"), "upper")
        XCTAssertNil(meta.firstValue(for: "Url"))
    }

    func testCodableRoundTripPreservesDuplicateKeysAndOrder() throws {
        let original = PassMetadata(fields: [
            .init(key: "url", value: "https://a"),
            .init(key: "user", value: "alice"),
            .init(key: "url", value: "https://b"),
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PassMetadata.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.fields.count, 3)
        XCTAssertEqual(decoded.fields.map(\.key), ["url", "user", "url"])
        XCTAssertEqual(decoded.fields.map(\.value), [
            "https://a", "alice", "https://b",
        ])
    }

    func testEmptyStringNotesIsDistinctFromNil() throws {
        let withNil = PassMetadata(fields: [], notes: nil)
        let withEmpty = PassMetadata(fields: [], notes: "")
        XCTAssertNotEqual(withNil, withEmpty)

        let nilData = try JSONEncoder().encode(withNil)
        let emptyData = try JSONEncoder().encode(withEmpty)
        let decodedNil = try JSONDecoder().decode(PassMetadata.self, from: nilData)
        let decodedEmpty = try JSONDecoder().decode(PassMetadata.self, from: emptyData)
        XCTAssertNil(decodedNil.notes)
        XCTAssertEqual(decodedEmpty.notes, "")
    }

    func testFieldHashableDistinguishesKeyAndValue() {
        let f1 = PassMetadata.Field(key: "k", value: "v1")
        let f2 = PassMetadata.Field(key: "k", value: "v2")
        let f3 = PassMetadata.Field(key: "k", value: "v1")
        let set: Set<PassMetadata.Field> = [f1, f2, f3]
        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - PassSecret edge cases (no Codable — by design)

final class PassSecretRefinementTests: XCTestCase {

    func testPasswordPreservesWhitespaceAndNewlinesVerbatim() {
        // The first-line trim is a parser concern, not a model concern.
        // The model itself must store whatever it is given verbatim.
        let pwd = "  spaces and\ttabs and\nnewline  "
        let secret = PassSecret(password: pwd)
        XCTAssertEqual(secret.password, pwd)
    }

    func testEqualityIgnoresMetadataIdentityButRespectsContents() {
        let m1 = PassMetadata(fields: [.init(key: "u", value: "a")])
        let m2 = PassMetadata(fields: [.init(key: "u", value: "a")])
        XCTAssertEqual(
            PassSecret(password: "x", metadata: m1),
            PassSecret(password: "x", metadata: m2)
        )
        XCTAssertNotEqual(
            PassSecret(password: "x", metadata: m1),
            PassSecret(password: "y", metadata: m1)
        )
    }

    func testLargePasswordRoundTripsThroughEquality() {
        // Stress: ensure nothing in the value type silently truncates
        // or canonicalises long inputs.
        let big = String(repeating: "ω", count: 4096)
        let s1 = PassSecret(password: big)
        let s2 = PassSecret(password: big)
        XCTAssertEqual(s1, s2)
        XCTAssertEqual(s1.password.count, 4096)
    }

    func testIsSendable() {
        // Compile-time + metatype check that `Sendable` is wired in.
        XCTAssertTrue((PassSecret.self as Any) is any Sendable.Type)
    }
}

// MARK: - PassError edge cases

final class PassErrorRefinementTests: XCTestCase {

    func testHashableInSet() {
        let set: Set<PassError> = [
            .cancelled,
            .timedOut,
            .cancelled,
            .binaryNotFound("pass"),
            .binaryNotFound("pass"),
            .binaryNotFound("gpg"),
            .shellFailure(exitCode: 1, stderrExcerpt: "x"),
            .shellFailure(exitCode: 1, stderrExcerpt: "x"),
            .shellFailure(exitCode: 2, stderrExcerpt: "x"),
        ]
        XCTAssertEqual(set.count, 6)
    }

    func testStderrExcerptIsPartOfIdentity() {
        XCTAssertNotEqual(
            PassError.decryptionFailed(stderrExcerpt: "a"),
            PassError.decryptionFailed(stderrExcerpt: "b")
        )
        XCTAssertNotEqual(
            PassError.shellFailure(exitCode: 1, stderrExcerpt: "a"),
            PassError.shellFailure(exitCode: 1, stderrExcerpt: "b")
        )
    }

    func testParameterlessCasesAreDistinct() {
        let cases: [PassError] = [
            .pinentryNotConfigured, .timedOut, .cancelled,
        ]
        XCTAssertEqual(Set(cases).count, cases.count)
    }

    func testStoreNotFoundCarriesPath() {
        let err = PassError.storeNotFound(path: "/nope")
        guard case .storeNotFound(let path) = err else {
            return XCTFail("unexpected case")
        }
        XCTAssertEqual(path, "/nope")
    }

    // MARK: - Phase D.6 write-side cases

    func testWriteSideCasesEqualityAndPayload() {
        XCTAssertEqual(
            PassError.entryAlreadyExists(path: "a/b"),
            PassError.entryAlreadyExists(path: "a/b")
        )
        XCTAssertNotEqual(
            PassError.entryAlreadyExists(path: "a/b"),
            PassError.entryAlreadyExists(path: "a/c")
        )

        XCTAssertEqual(
            PassError.recipientNotFound(emailOrKeyId: "alice@x"),
            PassError.recipientNotFound(emailOrKeyId: "alice@x")
        )
        XCTAssertNotEqual(
            PassError.recipientNotFound(emailOrKeyId: "alice@x"),
            PassError.recipientNotFound(emailOrKeyId: "bob@y")
        )

        XCTAssertEqual(PassError.invalidGpgId, .invalidGpgId)
        XCTAssertEqual(PassError.invalidLength, .invalidLength)
        XCTAssertNotEqual(PassError.invalidGpgId, .invalidLength)

        XCTAssertEqual(
            PassError.sourceNotFound(path: "a"),
            PassError.sourceNotFound(path: "a")
        )
        XCTAssertNotEqual(
            PassError.sourceNotFound(path: "a"),
            PassError.sourceNotFound(path: "b")
        )

        XCTAssertEqual(
            PassError.writeFailed(reason: "disk full"),
            PassError.writeFailed(reason: "disk full")
        )
        XCTAssertEqual(
            PassError.writeFailed(reason: nil),
            PassError.writeFailed(reason: nil)
        )
        XCTAssertNotEqual(
            PassError.writeFailed(reason: nil),
            PassError.writeFailed(reason: "disk full")
        )
    }

    func testWriteSideCasesHashableInSet() {
        let set: Set<PassError> = [
            .entryAlreadyExists(path: "a/b"),
            .entryAlreadyExists(path: "a/b"),
            .entryAlreadyExists(path: "a/c"),
            .recipientNotFound(emailOrKeyId: "alice@x"),
            .recipientNotFound(emailOrKeyId: "alice@x"),
            .invalidGpgId,
            .invalidGpgId,
            .invalidLength,
            .sourceNotFound(path: "a"),
            .sourceNotFound(path: "b"),
            .writeFailed(reason: nil),
            .writeFailed(reason: "x"),
            .writeFailed(reason: "x"),
        ]
        XCTAssertEqual(set.count, 9)
    }

    func testWriteSideCasesAreDistinctFromReadSide() {
        let cases: [PassError] = [
            .entryAlreadyExists(path: "p"),
            .recipientNotFound(emailOrKeyId: "k"),
            .invalidGpgId,
            .sourceNotFound(path: "p"),
            .writeFailed(reason: "r"),
            .invalidLength,
            .timedOut,
            .cancelled,
            .pinentryNotConfigured,
        ]
        XCTAssertEqual(Set(cases).count, cases.count)
    }

    // MARK: - Phase D.6 presentation hints (on PassError)

    func testInlineRecoverableOnlyForEntryAlreadyExists() {
        XCTAssertTrue(PassError.entryAlreadyExists(path: "p").inlineRecoverable)

        let nonRecoverable: [PassError] = [
            .binaryNotFound("pass"), .pinentryNotConfigured,
            .decryptionFailed(stderrExcerpt: "x"),
            .storeNotFound(path: "/p"), .timedOut,
            .shellFailure(exitCode: 1, stderrExcerpt: "x"),
            .parsingFailed(reason: "x"), .cancelled,
            .recipientNotFound(emailOrKeyId: "k"), .invalidGpgId,
            .sourceNotFound(path: "p"), .writeFailed(reason: nil),
            .invalidLength,
        ]
        for error in nonRecoverable {
            XCTAssertFalse(
                error.inlineRecoverable,
                "expected \(error) to be non-recoverable inline"
            )
        }
    }

    func testOnboardingHintMappings() {
        XCTAssertEqual(
            PassError.recipientNotFound(emailOrKeyId: "alice@x").onboardingHint,
            .checkRecipients
        )
        XCTAssertEqual(
            PassError.invalidGpgId.onboardingHint,
            .initializeStore
        )

        let noHint: [PassError] = [
            .binaryNotFound("pass"), .pinentryNotConfigured,
            .decryptionFailed(stderrExcerpt: "x"),
            .storeNotFound(path: "/p"), .timedOut,
            .shellFailure(exitCode: 1, stderrExcerpt: "x"),
            .parsingFailed(reason: "x"), .cancelled,
            .entryAlreadyExists(path: "p"),
            .sourceNotFound(path: "p"), .writeFailed(reason: nil),
            .invalidLength,
        ]
        for error in noHint {
            XCTAssertNil(
                error.onboardingHint,
                "expected \(error) to have no onboarding hint"
            )
        }
    }

    func testAutoRefreshesOnlyForSourceNotFound() {
        XCTAssertTrue(PassError.sourceNotFound(path: "p").autoRefreshes)

        let noAutoRefresh: [PassError] = [
            .binaryNotFound("pass"), .pinentryNotConfigured,
            .decryptionFailed(stderrExcerpt: "x"),
            .storeNotFound(path: "/p"), .timedOut,
            .shellFailure(exitCode: 1, stderrExcerpt: "x"),
            .parsingFailed(reason: "x"), .cancelled,
            .entryAlreadyExists(path: "p"),
            .recipientNotFound(emailOrKeyId: "k"), .invalidGpgId,
            .writeFailed(reason: nil), .invalidLength,
        ]
        for error in noAutoRefresh {
            XCTAssertFalse(
                error.autoRefreshes,
                "expected \(error) to not trigger auto-refresh"
            )
        }
    }

    func testOnboardingHintEqualityAndDistinctness() {
        XCTAssertEqual(OnboardingHint.checkRecipients, .checkRecipients)
        XCTAssertEqual(OnboardingHint.initializeStore, .initializeStore)
        XCTAssertNotEqual(OnboardingHint.checkRecipients, .initializeStore)
    }
}

// MARK: - Concurrency safety on an in-memory PassManaging stub

/// Minimal actor-based `PassManaging` double used here to exercise
/// deterministic concurrent access. Storage is shielded by the actor;
/// the test asserts that under fan-out load every entry is observed
/// exactly once and no decryption is lost.
private actor InMemoryPassManager: PassManaging {

    private var entries: [PassEntry] = []
    private var secrets: [String: PassSecret] = [:]
    private let store: URL

    init(store: URL = URL(fileURLWithPath: "/tmp/kizba-concurrent-store")) {
        self.store = store
    }

    func add(_ entry: PassEntry, secret: PassSecret) {
        entries.append(entry)
        secrets[entry.path] = secret
    }

    func listEntries() async throws -> [PassEntry] { entries }

    func show(_ entry: PassEntry) async throws -> PassSecret {
        guard let secret = secrets[entry.path] else {
            throw PassError.decryptionFailed(stderrExcerpt: "missing")
        }
        return secret
    }

    nonisolated func storeLocation() -> URL { store }
}

final class DomainConcurrencyTests: XCTestCase {

    /// Fan out a fixed number of concurrent `add` calls on an actor-
    /// backed `PassManaging` stub; assert every write is observed and
    /// none are dropped. Deterministic: fixed iterations, no timing.
    func testConcurrentAddsAreNotLost() async throws {
        let manager = InMemoryPassManager()
        let count = 64

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<count {
                group.addTask {
                    let entry = PassEntry(path: "folder/item-\(index)")
                    let secret = PassSecret(password: "pwd-\(index)")
                    await manager.add(entry, secret: secret)
                }
            }
        }

        let listed = try await manager.listEntries()
        XCTAssertEqual(listed.count, count)
        XCTAssertEqual(Set(listed.map(\.path)).count, count)
    }

    /// Concurrent `show` calls against pre-populated state must each
    /// return the exact secret keyed by the requested entry path.
    func testConcurrentShowReturnsExactSecretPerEntry() async throws {
        let manager = InMemoryPassManager()
        let count = 32
        for index in 0..<count {
            let entry = PassEntry(path: "f/\(index)")
            let secret = PassSecret(password: "pwd-\(index)")
            await manager.add(entry, secret: secret)
        }

        let results = await withTaskGroup(
            of: (Int, String?).self,
            returning: [Int: String].self
        ) { group in
            for index in 0..<count {
                group.addTask {
                    let entry = PassEntry(path: "f/\(index)")
                    let secret = try? await manager.show(entry)
                    return (index, secret?.password)
                }
            }
            var collected: [Int: String] = [:]
            for await (index, password) in group {
                if let password {
                    collected[index] = password
                }
            }
            return collected
        }

        XCTAssertEqual(results.count, count)
        for index in 0..<count {
            XCTAssertEqual(results[index], "pwd-\(index)")
        }
    }

    /// `show` for an unknown entry must surface `decryptionFailed` even
    /// when issued concurrently with other in-flight calls.
    func testConcurrentShowSurfacesDecryptionFailure() async {
        let manager = InMemoryPassManager()
        await manager.add(
            PassEntry(path: "real"),
            secret: PassSecret(password: "ok")
        )

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<16 {
                group.addTask {
                    do {
                        _ = try await manager.show(PassEntry(path: "ghost"))
                        return false
                    } catch let error as PassError {
                        if case .decryptionFailed = error { return true }
                        return false
                    } catch {
                        return false
                    }
                }
            }
            for await ok in group {
                XCTAssertTrue(ok, "expected decryptionFailed for unknown entry")
            }
        }
    }
}
