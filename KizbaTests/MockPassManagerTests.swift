//
//  MockPassManagerTests.swift
//  KizbaTests
//
//  Tests for the debug-only `MockPassManager` fixture corpus and
//  `PassManaging` conformance. All fixtures are deterministic, so every
//  assertion compares against literal expected values.
//

#if DEBUG

import XCTest
@testable import Kizba

final class MockPassManagerTests: XCTestCase {

    // MARK: - Corpus shape

    func testMock_has20Fixtures() async throws {
        let manager = MockPassManager.preview()
        let entries = try await manager.listEntries()

        XCTAssertEqual(entries.count, 20, "Fixture corpus must contain exactly 20 entries.")

        // Pin first and last entries to lock the canonical ordering.
        XCTAssertEqual(entries.first?.path, "personal/email/gmail")
        XCTAssertEqual(entries.last?.path,  "archive/services/ftp")
    }

    func testFixtures_areDeterministicAcrossInstances() async throws {
        let a = try await MockPassManager.preview().listEntries()
        let b = try await MockPassManager.preview().listEntries()
        XCTAssertEqual(a, b, "Two independent preview instances must produce identical entry lists.")
    }

    func testFixtures_coverThreeFolders() async throws {
        let entries = try await MockPassManager.preview().listEntries()
        let topLevel = Set(entries.map { $0.path.split(separator: "/").first.map(String.init) ?? "" })
        XCTAssertEqual(topLevel, ["personal", "work", "archive"])
    }

    func testFixtures_includeEdgeCases() async throws {
        let entries = try await MockPassManager.preview().listEntries()
        let paths = Set(entries.map(\.path))

        // Special-character entry name.
        XCTAssertTrue(paths.contains("personal/email/jane+filter@example.com"))

        // Empty trailing component yields an empty `name`.
        let empty = entries.first { $0.path == "personal/empty-name/" }
        XCTAssertNotNil(empty)
        XCTAssertEqual(empty?.name, "")
    }

    // MARK: - show(_:)

    func testShow_returnsExpectedEntry() async throws {
        let manager = MockPassManager.preview()
        let entry = PassEntry(path: "work/aws/root")

        let secret = try await manager.show(entry)

        XCTAssertEqual(secret.password, "aws-root-MFA-required")
        XCTAssertEqual(secret.metadata.firstValue(for: "user"), "root@example-org.aws")
        XCTAssertEqual(secret.metadata.firstValue(for: "mfa"),  "yubikey-5c-nfc")
        XCTAssertEqual(secret.metadata.notes, "Break-glass account. Use only with two-person rule.")
        XCTAssertNotNil(secret.metadata.firstValue(for: "created"))
    }

    func testShow_passwordOnlyEntry_hasEmptyMetadata() async throws {
        let manager = MockPassManager.preview()
        let secret = try await manager.show(PassEntry(path: "personal/wifi/home"))

        XCTAssertEqual(secret.password, "correct horse battery staple")
        XCTAssertTrue(secret.metadata.fields.isEmpty)
        XCTAssertNil(secret.metadata.notes)
    }

    func testShow_unknownEntry_throwsDecryptionFailed() async {
        let manager = MockPassManager.preview()
        let unknown = PassEntry(path: "nope/does-not-exist")

        do {
            _ = try await manager.show(unknown)
            XCTFail("Expected decryptionFailed for unknown entry.")
        } catch let error as PassError {
            switch error {
            case .decryptionFailed:
                break  // expected
            default:
                XCTFail("Unexpected PassError case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - storeLocation()

    func testStoreLocation_returnsFileURL() {
        let manager = MockPassManager.preview()
        let url = manager.storeLocation()

        XCTAssertTrue(url.isFileURL, "storeLocation must return a file URL.")
        XCTAssertEqual(url.path, "/tmp/kizba-mock-store")
    }

    func testStoreLocation_honoursCustomURL() {
        let custom = URL(fileURLWithPath: "/tmp/kizba-mock-custom")
        let manager = MockPassManager(entries: [], secrets: [:], storeLocation: custom)
        XCTAssertEqual(manager.storeLocation(), custom)
    }

    // MARK: - Concurrency

    func testConcurrency_readers_consistentResults() async throws {
        let manager = MockPassManager.preview()
        let baseline = try await manager.listEntries()
        let target = PassEntry(path: "work/github/personal-token")
        let baselineSecret = try await manager.show(target)

        // 64 concurrent reads each performing a list + a show; assert
        // every observation matches the baseline. No timing assertions.
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<64 {
                group.addTask {
                    let entries = try await manager.listEntries()
                    XCTAssertEqual(entries, baseline)
                    let secret = try await manager.show(target)
                    XCTAssertEqual(secret, baselineSecret)
                }
            }
            try await group.waitForAll()
        }
    }

    // MARK: - Write surface (Phase E.5)

    func testInsert_newEntry_appendsAndReturnsEntry() async throws {
        let manager = MockPassManager(entries: [], secrets: [:])
        let entry = PassEntry(path: "new/foo")
        let secret = PassSecret(password: "pw")

        let returned = try await manager.insert(entry, secret: secret, force: false)
        XCTAssertEqual(returned.path, "new/foo")

        let listed = try await manager.listEntries()
        XCTAssertEqual(listed.map(\.path), ["new/foo"])

        let fetched = try await manager.show(entry)
        XCTAssertEqual(fetched.password, "pw")
    }

    func testInsert_existingEntryWithoutForce_throwsAlreadyExists() async {
        let entry = PassEntry(path: "existing/foo")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "old")]
        )

        do {
            _ = try await manager.insert(
                entry,
                secret: PassSecret(password: "new"),
                force: false
            )
            XCTFail("Expected entryAlreadyExists")
        } catch PassError.entryAlreadyExists(let path) {
            XCTAssertEqual(path, "existing/foo")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInsert_existingEntryWithForce_overwritesAndEmitsUpdated() async throws {
        let entry = PassEntry(path: "existing/foo")
        let manager = MockPassManager(
            entries: [entry],
            secrets: [entry.path: PassSecret(password: "old")]
        )

        // Subscribe BEFORE the mutation so the emission is captured.
        let stream = await manager.changes
        let collector = Task { () -> StoreChange? in
            for await change in stream { return change }
            return nil
        }
        // Tiny sleep so the subscription is registered with the actor
        // before we trigger the mutation.
        try await Task.sleep(for: .milliseconds(20))

        _ = try await manager.insert(
            entry,
            secret: PassSecret(password: "new"),
            force: true
        )

        let fetched = try await manager.show(entry)
        XCTAssertEqual(fetched.password, "new")

        let event = await collector.value
        XCTAssertEqual(event, .updated(path: "existing/foo"))
    }

    func testRemove_missingEntry_throwsSourceNotFound() async {
        let manager = MockPassManager(entries: [], secrets: [:])
        let entry = PassEntry(path: "missing/foo")

        do {
            try await manager.remove(entry)
            XCTFail("Expected sourceNotFound")
        } catch PassError.sourceNotFound(let path) {
            XCTAssertEqual(path, "missing/foo")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMove_targetCollisionWithoutForce_throwsAlreadyExists() async {
        let from = PassEntry(path: "a/b")
        let to = PassEntry(path: "c/d")
        let manager = MockPassManager(
            entries: [from, to],
            secrets: [
                from.path: PassSecret(password: "x"),
                to.path: PassSecret(password: "y"),
            ]
        )

        do {
            _ = try await manager.move(from: from, to: to.path, force: false)
            XCTFail("Expected entryAlreadyExists")
        } catch PassError.entryAlreadyExists(let path) {
            XCTAssertEqual(path, "c/d")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testChanges_streamEmitsInsertedEvent() async throws {
        let manager = MockPassManager(entries: [], secrets: [:])

        let stream = await manager.changes
        let collector = Task { () -> StoreChange? in
            for await change in stream { return change }
            return nil
        }
        try await Task.sleep(for: .milliseconds(20))

        _ = try await manager.insert(
            PassEntry(path: "new/foo"),
            secret: PassSecret(password: "pw"),
            force: false
        )

        let event = await collector.value
        XCTAssertEqual(event, .inserted(path: "new/foo"))
    }
}

#endif
