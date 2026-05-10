import Foundation

// Test-only helper for creating and mutating a temporary store on disk.
// Provides a minimal, synchronous API used by opt-in FSEvents tests.
// Keep implementation Foundation-only to avoid test target coupling.
struct TempStoreFixture {
    // Instance-backed helper retained for older tests that expect
    // a TempStoreFixture value with `root`, `createStandardLayout()`,
    // `createEmptyStore()` and `cleanup()` instance methods.

    /// The root URL of the temporary store instance.
    let root: URL

    /// Create and return an instance bound to a unique dir under tmp.
    /// Non-throwing initializer for historical tests that expect
    /// `TempStoreFixture()` to succeed without `try`.
    init(prefix: String = "kizba-tempstore-") {
        let uuid = UUID().uuidString
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(prefix + uuid)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.root = dir
    }

    /// Remove the temporary store created by this instance.
    func cleanup() {
        try? FileManager.default.removeItem(at: root)
    }

    /// Create an empty store directory (no entries).
    func createEmptyStore() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    /// Create a standard test layout containing a mix of entries,
    /// hidden files, and ignorable artifacts (.gpg-id, .git, readme).
    func createStandardLayout() throws {
        try createEmptyStore()

        func write(_ rel: String, contents: String = "fixture") throws {
            let url = root.appendingPathComponent(rel)
            let folder = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try Data(contents.utf8).write(to: url, options: .atomic)
        }

        // Entries (gpg files) matching expectations in tests
        try write("archive/old.gpg")
        try write("pass.gpg")
        try write("personal/two.gpg")
        try write("personal/work/one.gpg")
        try write("work/entry.gpg")
        try write("スペース dir/entry name ☃.gpg")

        // Ignored metadata and VCS
        try write(".gpg-id", contents: "keyid")
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try write("readme.txt", contents: "This is a README and not a .gpg file")

        // Extra ignored file
        try write("ignored_file.tmp", contents: "ignore")
    }

    // MARK: - Static convenience API (for FSEvents tests)

    /// Create a unique temporary directory and return its URL.
    /// The directory is created under FileManager.default.temporaryDirectory.
    /// Caller is responsible for removing it via `removeTempStore` when done.
    static func createTempStore(prefix: String = "kizba-tempstore-") throws -> URL {
        let uuid = UUID().uuidString
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(prefix + uuid)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Write a file at the given relative path (create intermediate dirs).
    /// Returns the file URL written.
    static func writeFile(store: URL, relativePath: String, contents: Data) throws -> URL {
        let fileURL = store.appendingPathComponent(relativePath)
        let folder = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try contents.write(to: fileURL, options: .atomic)
        return fileURL
    }

    /// Touch a file (create empty file if it does not exist).
    /// Returns the touched file URL.
    static func touch(store: URL, relativePath: String) throws -> URL {
        let fileURL = store.appendingPathComponent(relativePath)
        let folder = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try Data().write(to: fileURL, options: .atomic)
        } else {
            // Update modification date by writing zero-length data atomically.
            try Data().write(to: fileURL, options: .atomic)
        }
        return fileURL
    }

    /// Delete the file at relative path if it exists.
    static func delete(store: URL, relativePath: String) throws {
        let fileURL = store.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    /// Remove the entire temporary store directory recursively.
    static func removeTempStore(store: URL) throws {
        if FileManager.default.fileExists(atPath: store.path) {
            try FileManager.default.removeItem(at: store)
        }
    }
}
