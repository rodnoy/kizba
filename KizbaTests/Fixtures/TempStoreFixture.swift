//
//  TempStoreFixture.swift
//  KizbaTests
//
//  Deterministic on-disk fixture for password-store tests
//  (Phase 6.4). Builds a fixed directory layout under a unique
//  temporary directory so that scanner / lister tests can assert
//  exact, repeatable expectations without ad-hoc per-test wiring.
//
//  ## Contract
//
//  - `init(name:)` creates a unique temp directory under
//    `FileManager.default.temporaryDirectory`.
//  - `createStandardLayout()` writes a fixed set of files with
//    deterministic names. File contents are short ASCII placeholders
//    (`"fixture"`); no real secrets are ever written.
//  - `createEmptyStore()` ensures the root exists and is empty.
//  - `cleanup()` removes the entire temp directory tree. Tests are
//    expected to call `cleanup()` from a `defer` block.
//
//  The fixture is intentionally synchronous and uses
//  `FileManager.default` directly — the same approach used by the
//  scanner under test.
//

import Foundation

/// A deterministic, throw-free temporary password-store fixture.
///
/// The fixture is a value type: each test instantiates its own copy
/// with its own unique temp root, so parallel test execution is safe.
struct TempStoreFixture {

    /// Absolute file URL to the fixture's temporary root directory.
    let root: URL

    /// Creates a unique temporary directory under
    /// `FileManager.default.temporaryDirectory`. The directory is
    /// created eagerly so that `root` is always usable.
    ///
    /// - Parameter name: a human-readable prefix for the temp folder
    ///   name. A UUID suffix guarantees uniqueness regardless of `name`.
    init(name: String = "temp-store-fixture") {
        let unique = "\(name)-\(UUID().uuidString)"
        self.root = FileManager.default.temporaryDirectory
            .appendingPathComponent(unique, isDirectory: true)
        // Best-effort eager creation. Tests that need to assert a
        // missing root build their target URL by appending to `root`.
        try? FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Layouts

    /// Writes the canonical mixed layout used by scanner tests.
    ///
    /// Layout (relative to `root`):
    ///
    /// - `pass.gpg`
    /// - `personal/two.gpg`
    /// - `personal/work/one.gpg`
    /// - `work/entry.gpg`
    /// - `archive/old.gpg`
    /// - `.gpg-id`                   (marker, must be ignored)
    /// - `.git/ignored.gpg`          (under `.git`, must be ignored)
    /// - `readme.txt`                (non-`.gpg`, must be ignored)
    /// - `スペース dir/entry name ☃.gpg` (unicode + spaces)
    func createStandardLayout() throws {
        try writeFile("pass.gpg")
        try writeFile("personal/two.gpg")
        try writeFile("personal/work/one.gpg")
        try writeFile("work/entry.gpg")
        try writeFile("archive/old.gpg")
        try writeFile(".gpg-id", contents: "fixture@example.com")
        try writeFile(".git/ignored.gpg")
        try writeFile("readme.txt")
        try writeFile("スペース dir/entry name ☃.gpg")
    }

    /// Ensures the root exists and contains no entries.
    func createEmptyStore() throws {
        if FileManager.default.fileExists(atPath: root.path) {
            try FileManager.default.removeItem(at: root)
        }
        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
    }

    /// Removes the temporary directory tree. Idempotent: safe to call
    /// even if the root has already been removed.
    func cleanup() {
        if FileManager.default.fileExists(atPath: root.path) {
            try? FileManager.default.removeItem(at: root)
        }
    }

    // MARK: - Helpers

    /// Writes a deterministic placeholder file at the given relative
    /// path, creating intermediate directories as needed.
    private func writeFile(_ relativePath: String, contents: String = "fixture") throws {
        let url = root.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }
}
