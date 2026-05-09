//
//  DomainProtocolsTests.swift
//  KizbaTests
//
//  Conformance and basic-behaviour tests for the Phase 1.2 domain
//  protocols. Each protocol is exercised through a minimal in-test
//  double to confirm the surface compiles, the threading annotations
//  are correct, and the documented round-trip semantics hold.
//

import XCTest
@testable import Kizba

// MARK: - PassManaging

/// In-memory test double covering the read-only ``PassManaging``
/// surface. Stores fixtures keyed by entry path.
private actor StubPassManager: PassManaging {

    private let entries: [PassEntry]
    private let secrets: [String: PassSecret]
    private let store: URL

    init(
        entries: [PassEntry],
        secrets: [String: PassSecret],
        store: URL = URL(fileURLWithPath: "/tmp/kizba-stub-store")
    ) {
        self.entries = entries
        self.secrets = secrets
        self.store = store
    }

    func listEntries() async throws -> [PassEntry] { entries }

    func show(_ entry: PassEntry) async throws -> PassSecret {
        guard let secret = secrets[entry.path] else {
            throw PassError.decryptionFailed(stderrExcerpt: "missing fixture")
        }
        return secret
    }

    nonisolated func storeLocation() -> URL { store }
}

final class PassManagingTests: XCTestCase {

    func testListEntriesReturnsFixture() async throws {
        let entry = PassEntry(path: "work/aws/root")
        let manager = StubPassManager(entries: [entry], secrets: [:])
        let listed = try await manager.listEntries()
        XCTAssertEqual(listed, [entry])
    }

    func testShowRoundTrip() async throws {
        let entry = PassEntry(path: "work/aws/root")
        let secret = PassSecret(
            password: "hunter2",
            metadata: PassMetadata(fields: [.init(key: "url", value: "https://aws")])
        )
        let manager = StubPassManager(
            entries: [entry],
            secrets: [entry.path: secret]
        )
        let decrypted = try await manager.show(entry)
        XCTAssertEqual(decrypted, secret)
    }

    func testShowSurfacesDecryptionFailureForUnknownEntry() async {
        let manager = StubPassManager(entries: [], secrets: [:])
        do {
            _ = try await manager.show(PassEntry(path: "ghost"))
            XCTFail("expected PassError")
        } catch let error as PassError {
            if case .decryptionFailed = error { return }
            XCTFail("unexpected case: \(error)")
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testStoreLocationIsExposed() {
        let url = URL(fileURLWithPath: "/tmp/store")
        let manager = StubPassManager(entries: [], secrets: [:], store: url)
        XCTAssertEqual(manager.storeLocation(), url)
    }
}

// MARK: - ShellCommandRunning

/// Records the most recent invocation and replays a canned result.
private final class RecordingShellRunner: ShellCommandRunning, @unchecked Sendable {

    struct Invocation: Equatable {
        let executable: URL
        let arguments: [String]
        let environment: [String: String]
        let timeout: Duration
    }

    private let lock = NSLock()
    private var _last: Invocation?
    private let result: ShellResult

    init(result: ShellResult) { self.result = result }

    var last: Invocation? {
        lock.lock(); defer { lock.unlock() }
        return _last
    }

    func run(_ invocation: ShellInvocation) async throws -> ShellResult {
        lock.lock()
        _last = Invocation(
            executable: invocation.executable,
            arguments: invocation.arguments,
            environment: invocation.environment,
            timeout: invocation.timeout
        )
        lock.unlock()
        return result
    }
}

final class ShellCommandRunningTests: XCTestCase {

    func testRunForwardsArgumentsAndReturnsResult() async throws {
        let expected = ShellResult(
            exitCode: 0,
            standardOutput: Data("ok".utf8),
            standardError: Data()
        )
        let runner = RecordingShellRunner(result: expected)
        let result = try await runner.run(
            executable: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: ["--flag"],
            environment: ["PATH": "/usr/bin"],
            timeout: .seconds(1)
        )
        XCTAssertEqual(result, expected)
        XCTAssertEqual(runner.last?.arguments, ["--flag"])
        XCTAssertEqual(runner.last?.environment["PATH"], "/usr/bin")
        XCTAssertEqual(runner.last?.timeout, .seconds(1))
    }
}

// MARK: - ClipboardServicing

// `FakeClipboardServicing` lives in `KizbaTests/Fixtures/FakeClipboard.swift`.

final class ClipboardServicingTests: XCTestCase {

    func testCopyRecordsValueVerbatim() async {
        let clipboard = FakeClipboardServicing()
        await clipboard.copy("hunter2", clearAfter: .seconds(30))
        XCTAssertEqual(
            clipboard.calls,
            [.init(value: "hunter2", clearAfter: .seconds(30))]
        )
    }

    func testRepeatedCopiesAreOrdered() async {
        let clipboard = FakeClipboardServicing()
        await clipboard.copy("a", clearAfter: .seconds(30))
        await clipboard.copy("b", clearAfter: .seconds(10))
        XCTAssertEqual(clipboard.calls.map(\.value), ["a", "b"])
    }
}

// MARK: - BinaryLocating

/// In-memory locator that returns canned URLs and counts re-detections.
private actor StubBinaryLocator: BinaryLocating {

    private var paths: [BinaryName: URL]
    private(set) var reDetectCount: Int = 0

    init(paths: [BinaryName: URL]) { self.paths = paths }

    func locate(_ binary: BinaryName) async -> URL? { paths[binary] }

    func reDetect() async {
        reDetectCount += 1
        paths = [:]
    }
}

final class BinaryLocatingTests: XCTestCase {

    func testLocateReturnsConfiguredURL() async {
        let url = URL(fileURLWithPath: "/opt/homebrew/bin/pass")
        let locator = StubBinaryLocator(paths: [.pass: url])
        let resolved = await locator.locate(.pass)
        XCTAssertEqual(resolved, url)
    }

    func testLocateReturnsNilWhenMissing() async {
        let locator = StubBinaryLocator(paths: [:])
        let resolved = await locator.locate(.gpg)
        XCTAssertNil(resolved)
    }

    func testReDetectClearsCache() async {
        let url = URL(fileURLWithPath: "/usr/bin/gpg")
        let locator = StubBinaryLocator(paths: [.gpg: url])
        let before = await locator.locate(.gpg)
        XCTAssertNotNil(before)
        await locator.reDetect()
        let count = await locator.reDetectCount
        XCTAssertEqual(count, 1)
        let after = await locator.locate(.gpg)
        XCTAssertNil(after)
    }

    func testBinaryNameRawValues() {
        XCTAssertEqual(BinaryName.pass.rawValue, "pass")
        XCTAssertEqual(BinaryName.gpg.rawValue, "gpg")
        XCTAssertEqual(BinaryName.pinentryMac.rawValue, "pinentry-mac")
    }
}

// MARK: - SettingsStoring

/// In-memory settings store used to validate the protocol's
/// type-erased read/write contract.
private final class InMemorySettingsStore: SettingsStoring, @unchecked Sendable {

    private let lock = NSLock()
    private var storage: [String: Any] = [:]

    func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? {
        lock.lock(); defer { lock.unlock() }
        return storage[key.name] as? Value
    }

    func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {
        lock.lock(); defer { lock.unlock() }
        if let value {
            storage[key.name] = value
        } else {
            storage.removeValue(forKey: key.name)
        }
    }

    func removeValue(forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    func resetAll() {
        lock.lock(); defer { lock.unlock() }
        storage.removeAll()
    }

    func registerDefaults(_ defaults: [String: Any]) {
        lock.lock(); defer { lock.unlock() }
        for (k, v) in defaults where storage[k] == nil {
            if let s = v as? String { storage[k] = s }
            else if let i = v as? Int { storage[k] = i }
            else if let d = v as? Double { storage[k] = d }
            else if let b = v as? Bool { storage[k] = b }
        }
    }
}

final class SettingsStoringTests: XCTestCase {

    func testRoundTripStringAndInt() {
        let store = InMemorySettingsStore()
        let path = SettingsKey<String>("storePathOverride")
        let delay = SettingsKey<Int>("clipboardClearDelaySeconds")

        store.set("/tmp/store", for: path)
        store.set(45, for: delay)

        XCTAssertEqual(store.value(for: path), "/tmp/store")
        XCTAssertEqual(store.value(for: delay), 45)
    }

    func testNilRemovesEntry() {
        let store = InMemorySettingsStore()
        let key = SettingsKey<Bool>("revealByDefault")
        store.set(true, for: key)
        XCTAssertEqual(store.value(for: key), true)
        store.set(nil, for: key)
        XCTAssertNil(store.value(for: key))
    }

    func testKeysAreIsolated() {
        let store = InMemorySettingsStore()
        let a = SettingsKey<Int>("a")
        let b = SettingsKey<Int>("b")
        store.set(1, for: a)
        store.set(2, for: b)
        XCTAssertEqual(store.value(for: a), 1)
        XCTAssertEqual(store.value(for: b), 2)
    }
}
