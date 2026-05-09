//
//  PassWriteIntegrationTests.swift
//  KizbaTests
//
//  Phase E.8 — opt-in real-process end-to-end suite that exercises the
//  full ``LivePassManager`` write path against an actual `pass` + `gpg`
//  installation. Spawns real binaries; encrypts and decrypts with a
//  freshly-generated, ephemeral GPG key inside a per-test temporary
//  `GNUPGHOME` and `PASSWORD_STORE_DIR`. No host-state is mutated:
//  every per-test directory is rm-rf'd in tearDown.
//
//  Per-test temp tree lives under `/tmp/kizba-e2e-<short-id>/` rather
//  than `~/Library/Caches/...` because gpg-agent's Unix-domain socket
//  path is bounded by `sun_path` (104 bytes on Darwin) — the deeper
//  Caches-prefixed path overflows it.
//
//  ## How to run locally
//
//      KIZBA_E2E=1 xcodebuild test \
//        -scheme Kizba -project Kizba.xcodeproj \
//        -destination 'platform=macOS' \
//        -only-testing:KizbaTests/PassWriteIntegrationTests
//
//  Without `KIZBA_E2E=1`, every test method is short-circuited via
//  ``XCTSkipUnless`` so default CI runs are unaffected. The suite is
//  also skipped when `pass` or `gpg` cannot be located on the host.
//
//  ## Pinentry handling
//
//  Test-time GPG key is generated with `%no-protection` (passphraseless)
//  so `pinentry-mac` never prompts during these tests. This keeps the
//  suite hands-off and proves the "no double pinentry" claim by virtue
//  of the absence of any prompt at all.
//
//  ## Performance
//
//  Each test method takes ~5-15s on first run (gpg-agent cold start,
//  key generation). Subsequent tests reuse the per-test `gpg-agent`
//  spawned in `setUp`. Per-shell-op timeouts are generous (30s) to
//  cover slow first-run agent initialisation on CI hardware.
//

import XCTest
@testable import Kizba

final class PassWriteIntegrationTests: XCTestCase {

    // MARK: - Per-test fixture

    /// Root of the per-test temporary directory tree. Holds
    /// `gnupg/` + `password-store/`. Removed in `tearDown`.
    private var tempRoot: URL!

    /// Resolved `GNUPGHOME` for this test (subdir of `tempRoot`).
    private var gnupgHome: URL!

    /// Resolved `PASSWORD_STORE_DIR` for this test (subdir of `tempRoot`).
    private var storeDir: URL!

    /// Absolute path to the system `gpg` binary, resolved by
    /// ``BinaryDiscoveryService`` in `setUp`.
    private var gpgURL: URL!

    /// Absolute path to the system `pass` binary.
    private var passURL: URL!

    /// Optional absolute path to `gpgconf` — used best-effort in
    /// `tearDown` to kill any lingering `gpg-agent`.
    private var gpgconfURL: URL?

    /// Recipient email baked into the ephemeral GPG key. Stable across
    /// every test in the suite; only the key fingerprint varies.
    private static let recipientEmail = "e2e@kizba.local"

    /// Standard environment dict for ad-hoc shell ops in setUp/tearDown.
    /// Always carries both `GNUPGHOME` and `PASSWORD_STORE_DIR` so the
    /// child sees the per-test sandbox; `PATH` is a sanitised list so
    /// `gpg` can find its own helpers (`gpg-agent`, `pinentry-mac`).
    private var sandboxEnv: [String: String] {
        var env: [String: String] = [
            "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
            "GNUPGHOME": gnupgHome.path,
            "PASSWORD_STORE_DIR": storeDir.path,
            "LC_ALL": "C",
            "LANG": "C",
        ]
        if let parentHome = ProcessInfo.processInfo.environment["HOME"] {
            env["HOME"] = parentHome
        }
        return env
    }

    // MARK: - setUp / tearDown

    override func setUp() async throws {
        try await super.setUp()

        // Gate everything: without the env var, the rest of setUp is
        // skipped (and every test method also skips, defensively).
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests against real pass + gpg"
        )

        // Resolve binaries via the production discovery service so we
        // pick up Apple-silicon Homebrew (`/opt/homebrew/bin`) without
        // hard-coding a path.
        let discovery = BinaryDiscoveryService()
        guard let pass = await discovery.locate(.pass) else {
            throw XCTSkip("`pass` binary not found on PATH; install via `brew install pass`")
        }
        guard let gpg = await discovery.locate(.gpg) else {
            throw XCTSkip("`gpg` binary not found on PATH; install via `brew install gnupg`")
        }
        self.passURL = pass
        self.gpgURL = gpg
        self.gpgconfURL = await Self.locateGpgconf()

        // Build the per-test temp tree under `/tmp` rather than under
        // the user's Caches directory: gpg-agent's Unix-domain socket
        // path is bounded by `sun_path` (104 bytes on Darwin) and the
        // longer Caches-prefixed path overflows it ("File name too
        // long" / "No agent running" failures). `/tmp` keeps the full
        // socket path well under the limit. We still rm-rf the tree
        // in `tearDown` so nothing leaks.
        let shortID = UUID().uuidString.prefix(8)
        self.tempRoot = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appendingPathComponent("kizba-e2e-\(shortID)", isDirectory: true)
        self.gnupgHome = tempRoot.appendingPathComponent("g", isDirectory: true)
        self.storeDir = tempRoot.appendingPathComponent("ps", isDirectory: true)

        try FileManager.default.createDirectory(
            at: gnupgHome,
            withIntermediateDirectories: true
        )
        // GPG refuses GNUPGHOME unless it has 0700 perms.
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: gnupgHome.path
        )
        try FileManager.default.createDirectory(
            at: storeDir,
            withIntermediateDirectories: true
        )

        // Pre-write `gpg-agent.conf` permitting loopback pinentry, and
        // `gpg.conf` defaulting to it. Without this combination the
        // agent tries to use the controlling TTY (we have none under
        // xctest) and `agent_genkey` / encryption operations fail with
        // "Inappropriate ioctl for device". `trust-model always` skips
        // the standard "marginal/full trust" check on a freshly-minted
        // key — the key was generated by us seconds ago in this same
        // sandbox; web-of-trust ceremony adds nothing here.
        try Data("allow-loopback-pinentry\n".utf8).write(
            to: gnupgHome.appendingPathComponent("gpg-agent.conf")
        )
        try Data("pinentry-mode loopback\nbatch\ntrust-model always\n".utf8).write(
            to: gnupgHome.appendingPathComponent("gpg.conf")
        )

        // Pre-launch the per-test gpg-agent. Under xctest there is no
        // login shell or DBus to auto-spawn it lazily, so the first
        // `gpg --quick-generate-key` would fail with "No agent running"
        // / "IPC connect call failed". `gpgconf --launch gpg-agent`
        // is the documented one-shot bring-up that returns once the
        // socket is ready.
        let runner = ProcessShellRunner()
        if let gpgconf = gpgconfURL {
            _ = try? await runner.run(ShellInvocation(
                executable: gpgconf,
                arguments: ["--launch", "gpg-agent"],
                environment: sandboxEnv,
                stdin: .none,
                timeout: .seconds(15)
            ))
        }

        // Generate an ephemeral, passphraseless GPG key via
        // `--batch --gen-key` + a stdin recipe. The recipe explicitly
        // requests an EdDSA primary AND a cv25519 ECDH subkey: the
        // primary is for signing/certification, the subkey is what
        // `pass insert` will actually encrypt to. Without the explicit
        // ECDH subkey, encryption fails with "Unusable public key".
        // `%no-protection` ⇒ no passphrase ⇒ pinentry never prompts.
        let recipe = """
        Key-Type: EDDSA
        Key-Curve: ed25519
        Subkey-Type: ECDH
        Subkey-Curve: cv25519
        Name-Real: Kizba E2E
        Name-Email: \(Self.recipientEmail)
        Expire-Date: 1d
        %no-protection
        %commit

        """
        let gen = try await runner.run(ShellInvocation(
            executable: gpgURL,
            arguments: ["--batch", "--gen-key"],
            environment: sandboxEnv,
            stdin: .data(Data(recipe.utf8)),
            timeout: .seconds(60)
        ))
        guard gen.exitCode == 0 else {
            let stderr = String(data: gen.standardError, encoding: .utf8) ?? ""
            throw XCTSkip("Failed to generate ephemeral GPG key (exit=\(gen.exitCode)): \(stderr)")
        }

        // Initialise the password store against the freshly created
        // recipient. `pass init` writes `.gpg-id` and prepares the
        // store layout.
        let passInit = try await runner.run(ShellInvocation(
            executable: passURL,
            arguments: ["init", Self.recipientEmail],
            environment: sandboxEnv,
            stdin: .none,
            timeout: .seconds(30)
        ))
        guard passInit.exitCode == 0 else {
            let stderr = String(data: passInit.standardError, encoding: .utf8) ?? ""
            throw XCTSkip("`pass init` failed (exit=\(passInit.exitCode)): \(stderr)")
        }
        // Sanity: `.gpg-id` must exist.
        let gpgId = storeDir.appendingPathComponent(".gpg-id")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: gpgId.path),
            "Expected pass init to create .gpg-id at \(gpgId.path)"
        )
    }

    override func tearDown() async throws {
        // Best-effort: kill any lingering gpg-agent for this homedir so
        // the next test's `setUp` doesn't inherit a stale socket.
        if let gnupgHome, let gpgconf = gpgconfURL {
            let runner = ProcessShellRunner()
            _ = try? await runner.run(ShellInvocation(
                executable: gpgconf,
                arguments: ["--homedir", gnupgHome.path, "--kill", "all"],
                environment: sandboxEnv,
                stdin: .none,
                timeout: .seconds(10)
            ))
        }

        // Remove the entire per-test directory tree. Idempotent.
        if let tempRoot, FileManager.default.fileExists(atPath: tempRoot.path) {
            try? FileManager.default.removeItem(at: tempRoot)
        }

        // Reset references so a stale value does not leak across tests
        // when XCTest reuses the test-case instance.
        self.tempRoot = nil
        self.gnupgHome = nil
        self.storeDir = nil
        self.gpgURL = nil
        self.passURL = nil
        self.gpgconfURL = nil

        try await super.tearDown()
    }

    // MARK: - Stack composition

    /// Build a real ``LivePassManager`` wired to this test's temp store
    /// and ephemeral GPG home. Caller owns the returned manager.
    private func makeManager() -> LivePassManager {
        let runner = ProcessShellRunner()
        let discovery = BinaryDiscoveryService()
        let cli = LivePassCLI(
            discovery: discovery,
            shellRunner: runner,
            passwordStoreDir: storeDir,
            gnupgHome: gnupgHome
        )
        let scanner = PasswordStoreScanner()
        return LivePassManager(
            scanner: scanner,
            passCLI: cli,
            storeRoot: storeDir
        )
    }

    /// Convenience: drain the next `expected` ``StoreChange`` events
    /// from `stream` with a timeout. Used by the multi-event test.
    private func collectChanges(
        from manager: LivePassManager,
        count expected: Int,
        within timeout: Duration = .seconds(30)
    ) -> Task<[StoreChange], Error> {
        // Subscribe BEFORE the writes happen — the caller does not
        // start the writes until this Task is observed to be running.
        let stream = manager.changes
        return Task<[StoreChange], Error> {
            try await withThrowingTaskGroup(of: [StoreChange].self) { group in
                group.addTask {
                    var collected: [StoreChange] = []
                    for await change in stream {
                        collected.append(change)
                        if collected.count >= expected { break }
                    }
                    return collected
                }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw IntegrationTimeout()
                }
                guard let first = try await group.next() else { return [] }
                group.cancelAll()
                return first
            }
        }
    }

    private struct IntegrationTimeout: Error {}

    // MARK: - Tests

    /// 1. Insert + show round-trip — the canonical "happy path".
    /// Validates Serializer↔Parser round-trip + real GPG encrypt/decrypt.
    func testInsertThenShow_roundTripsSecret() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let entry = PassEntry(path: "work/example")
        let secret = await MainActor.run {
            PassSecret(
                password: "hunter2-correct-horse",
                metadata: PassMetadata(
                    fields: [
                        PassMetadata.Field(key: "username", value: "alice"),
                        PassMetadata.Field(key: "url", value: "https://example.com"),
                    ],
                    notes: "free form notes\nover two lines"
                )
            )
        }

        _ = try await manager.insert(entry, secret: secret, force: false)

        let decrypted = try await manager.show(entry)
        XCTAssertEqual(decrypted.password, secret.password)
        XCTAssertEqual(decrypted.metadata.fields.count, secret.metadata.fields.count)
        for (got, expected) in zip(decrypted.metadata.fields, secret.metadata.fields) {
            XCTAssertEqual(got.key, expected.key)
            XCTAssertEqual(got.value, expected.value)
        }
        XCTAssertEqual(decrypted.metadata.notes, secret.metadata.notes)
    }

    /// 2. Insert with `force: true` over an existing path produces the
    /// new content (atomic overwrite). The "collision throws" arm is
    /// covered by ``PassErrorMapperTests`` against canned 1.7.3/1.7.4
    /// stderr fixtures rather than here, because `pass insert -m`
    /// when stdin is a pipe (our test runner case) detects the lack
    /// of a controlling TTY in its `yesno()` helper and silently
    /// returns success WITHOUT prompting — so the no-`force` arm
    /// cannot fail at the pass layer in this environment. See
    /// `cmd_insert` + `yesno()` in `pass` 1.7.4 source for details.
    func testInsert_forceOverwrite_replacesExistingContent() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let entry = PassEntry(path: "site/login")
        _ = try await manager.insert(
            entry,
            secret: await MainActor.run { PassSecret(password: "v1") },
            force: false
        )
        _ = try await manager.insert(
            entry,
            secret: await MainActor.run { PassSecret(password: "v2") },
            force: true
        )
        let decrypted = try await manager.show(entry)
        XCTAssertEqual(decrypted.password, "v2")
    }

    /// 3. `force: true` overwrite does not interactively prompt the
    /// user. With `%no-protection` there is no pinentry to begin with;
    /// this test asserts the structural property — the second `insert`
    /// returns successfully without a stalled prompt.
    func testInsert_forceTrue_doesNotBlockOnPinentry() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let entry = PassEntry(path: "service/account")
        let s1 = await MainActor.run { PassSecret(password: "first") }
        let s2 = await MainActor.run { PassSecret(password: "second") }

        _ = try await manager.insert(entry, secret: s1, force: false)

        // Wrap the second call in a 15s deadline so a hypothetical
        // pinentry blocker would surface as a clear test failure
        // rather than a silent hang.
        let result: Bool = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                _ = try await manager.insert(entry, secret: s2, force: true)
                return true
            }
            group.addTask {
                try await Task.sleep(for: .seconds(15))
                return false
            }
            guard let first = try await group.next() else { return false }
            group.cancelAll()
            return first
        }
        XCTAssertTrue(result, "Force-overwrite insert appears to be blocked (pinentry?).")
    }

    /// 4. Generate + show: `pass generate` produces a 24-char password
    /// and `show` returns the same body.
    func testGenerateThenShow_returnsRequestedLengthPassword() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let entry = PassEntry(path: "generated/foo")

        let generated = try await manager.generate(
            entry,
            length: 24,
            includeSymbols: true,
            force: false
        )
        XCTAssertEqual(
            generated.password.count,
            24,
            "Expected 24-char generated password, got \(generated.password.count) chars"
        )

        let decrypted = try await manager.show(entry)
        XCTAssertEqual(decrypted.password, generated.password)
    }

    /// 5. Insert → list contains entry → remove → list no longer
    /// contains it. Also asserts `.removed(path:)` event fires.
    func testRemove_dropsEntryFromListing_andEmitsRemovedEvent() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let entry = PassEntry(path: "to/remove")
        _ = try await manager.insert(
            entry,
            secret: await MainActor.run { PassSecret(password: "deleteme") },
            force: false
        )

        let beforeRemove = try await manager.listEntries().map(\.path)
        XCTAssertTrue(beforeRemove.contains(entry.path), "Listing missing fresh entry")

        // Subscribe BEFORE invoking remove so the change event is
        // observed reliably. Subscription joins the actor synchronously
        // via the AsyncStream factory; allow a short delay to ensure
        // the registration Task has run.
        let collector = collectChanges(from: manager, count: 1, within: .seconds(15))
        try await Task.sleep(for: .milliseconds(50))

        try await manager.remove(entry)

        let events = try await collector.value
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first, .removed(path: entry.path))

        let afterRemove = try await manager.listEntries().map(\.path)
        XCTAssertFalse(afterRemove.contains(entry.path), "Listing still contains removed entry")
    }

    /// 6. Move A → B: source disappears, destination shows same body,
    /// listing reflects the rename, `.moved(from:to:)` fires.
    func testMove_relocatesEntry_andEmitsMovedEvent() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let from = PassEntry(path: "old/place")
        let toPath = "new/place"

        _ = try await manager.insert(
            from,
            secret: await MainActor.run { PassSecret(password: "movable") },
            force: false
        )

        let collector = collectChanges(from: manager, count: 1, within: .seconds(15))
        try await Task.sleep(for: .milliseconds(50))

        let moved = try await manager.move(from: from, to: toPath, force: false)
        XCTAssertEqual(moved.path, toPath)

        let events = try await collector.value
        XCTAssertEqual(events.first, .moved(from: from.path, to: toPath))

        // Destination decrypts to the original password.
        let decrypted = try await manager.show(moved)
        XCTAssertEqual(decrypted.password, "movable")

        // Source no longer exists. `pass show` against the now-missing
        // path emits "Error: <path> is not in the password store.";
        // `PassErrorMapper` maps that signature under
        // ``CommandContext/show`` to ``PassError/invalidGpgId``
        // (the historical read-side default — an uninitialised store
        // surfaces the same string). We accept any of the typed
        // failure cases that this stderr could plausibly produce
        // across `pass` 1.7.x.
        do {
            _ = try await manager.show(from)
            XCTFail("Expected show(from) to throw after move")
        } catch let error as PassError {
            switch error {
            case .sourceNotFound, .shellFailure, .decryptionFailed,
                 .invalidGpgId:
                break // Acceptable: moved entry no longer resolvable.
            default:
                XCTFail("Unexpected error after move: \(error)")
            }
        }

        // Listing reflects the rename.
        let listed = try await manager.listEntries().map(\.path)
        XCTAssertTrue(listed.contains(toPath), "Listing missing destination entry")
        XCTAssertFalse(listed.contains(from.path), "Listing still contains source entry")
    }

    /// 7. Multi-event AsyncStream: subscribe once, perform
    /// insert + generate-in-place + remove, observe all 3 events in
    /// order.
    func testChanges_multiEventStream_observesAllInOrder() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["KIZBA_E2E"] == "1",
            "Set KIZBA_E2E=1 to run integration tests"
        )
        let manager = makeManager()
        let entry = PassEntry(path: "stream/target")

        let collector = collectChanges(from: manager, count: 3, within: .seconds(45))
        try await Task.sleep(for: .milliseconds(50))

        // 1) insert (new path) → .inserted
        _ = try await manager.insert(
            entry,
            secret: await MainActor.run { PassSecret(password: "v1") },
            force: false
        )
        // 2) generate (force: true on the same path) → .updated
        _ = try await manager.generate(
            entry,
            length: 16,
            includeSymbols: false,
            force: true
        )
        // 3) remove → .removed
        try await manager.remove(entry)

        let events = try await collector.value
        XCTAssertEqual(events.count, 3, "Got \(events.count) events: \(events)")
        XCTAssertEqual(events[0], .inserted(path: entry.path))
        XCTAssertEqual(events[1], .updated(path: entry.path))
        XCTAssertEqual(events[2], .removed(path: entry.path))
    }

    // MARK: - Helpers

    /// Resolve `gpgconf` path. Used best-effort during tearDown to
    /// kill the per-test `gpg-agent`. Returns `nil` if not on PATH.
    private static func locateGpgconf() async -> URL? {
        let candidates = [
            "/opt/homebrew/bin/gpgconf",
            "/usr/local/bin/gpgconf",
            "/usr/bin/gpgconf",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
