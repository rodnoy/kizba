import Foundation

actor PassGitE2EHelper {

    enum HelperError: Error {
        case missingBinary(String)
        case invalidArguments
        case commandFailed(command: String, exitCode: Int32, stderr: String)
        case timedOut(command: String)
    }

    let workDir: URL

    private let gitURL: URL
    private let passURL: URL
    private let gpgURL: URL
    private let gpgconfURL: URL?
    private let gnupgHome: URL

    init() throws {
        let uuid = UUID().uuidString.lowercased()
        let root = URL(fileURLWithPath: "/tmp", isDirectory: true)
            .appendingPathComponent("kizba-git-e2e-\(uuid)", isDirectory: true)

        let git = try Self.resolveBinary(named: "git")
        let pass = try Self.resolveBinary(named: "pass")
        let gpg = try Self.resolveBinary(named: "gpg")
        let gpgconf = Self.resolveBinaryIfPresent(named: "gpgconf")

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let gnupg = root.appendingPathComponent("gnupg", isDirectory: true)
        try FileManager.default.createDirectory(at: gnupg, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: gnupg.path)

        self.workDir = root
        self.gitURL = git
        self.passURL = pass
        self.gpgURL = gpg
        self.gpgconfURL = gpgconf
        self.gnupgHome = gnupg
    }

    nonisolated func shell(
        _ args: [String],
        cwd: URL? = nil,
        env: [String: String]? = nil,
        timeoutSeconds: Int = 60
    ) throws -> (stdout: String, stderr: String, exitCode: Int32) {
        guard let first = args.first else {
            throw HelperError.invalidArguments
        }

        let process = Process()
        if first.contains("/") {
            process.executableURL = URL(fileURLWithPath: first)
            process.arguments = Array(args.dropFirst())
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = args
        }
        process.currentDirectoryURL = cwd
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = FileHandle.nullDevice

        try process.run()

        let deadline = Date().addingTimeInterval(TimeInterval(timeoutSeconds))
        while process.isRunning, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }

        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
            throw HelperError.timedOut(command: args.joined(separator: " "))
        }

        let stdoutData = try stdoutPipe.fileHandleForReading.readToEnd() ?? Data()
        let stderrData = try stderrPipe.fileHandleForReading.readToEnd() ?? Data()
        let rawStdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let rawStderr = String(data: stderrData, encoding: .utf8) ?? ""
        let safeStdout = Self.sanitize(rawStdout)
        let safeStderr = Self.sanitize(rawStderr)
        let exitCode = process.terminationStatus

        if exitCode != 0 {
            throw HelperError.commandFailed(
                command: args.joined(separator: " "),
                exitCode: exitCode,
                stderr: String(safeStderr.prefix(200))
            )
        }

        return (safeStdout, safeStderr, exitCode)
    }

    func makeBareRepo() throws -> URL {
        let bare = workDir.appendingPathComponent("bare.git", isDirectory: true)
        _ = try shell([gitURL.path, "init", "--bare", bare.path], cwd: workDir)
        return bare
    }

    func cloneRepo(from bare: URL, name: String) throws -> URL {
        let clone = workDir.appendingPathComponent(name, isDirectory: true)
        _ = try shell([gitURL.path, "clone", bare.path, clone.path], cwd: workDir)
        try configureGitIdentity(in: clone)
        return clone
    }

    func passInit(in repoDir: URL, gpgKeyID: String) throws {
        try configureGitIdentity(in: repoDir)
        try createEphemeralKey(identity: gpgKeyID)

        let passEnv = composedEnv(additions: ["PASSWORD_STORE_DIR": repoDir.path])
        _ = try shell([passURL.path, "init", gpgKeyID], cwd: repoDir, env: passEnv)

        let hasRemote = (try? shell([gitURL.path, "-C", repoDir.path, "remote", "get-url", "origin"])) != nil
        if hasRemote {
            _ = try shell([gitURL.path, "-C", repoDir.path, "add", ".gpg-id"])
            _ = try shell([
                gitURL.path,
                "-C",
                repoDir.path,
                "commit",
                "-m",
                "Initialize pass store for E2E"
            ])
            _ = try shell([gitURL.path, "-C", repoDir.path, "push", "-u", "origin", "HEAD"])
        }
    }

    func commitAndPush(in repoDir: URL, path: String, content: String, message: String) throws {
        let fileURL = repoDir.appendingPathComponent(path)
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try Data(content.utf8).write(to: fileURL)

        _ = try shell([gitURL.path, "-C", repoDir.path, "add", path])
        _ = try shell([gitURL.path, "-C", repoDir.path, "commit", "-m", message])
        _ = try shell([gitURL.path, "-C", repoDir.path, "push", "origin", "HEAD"])
    }

    func createConflict(between cloneA: URL, cloneB: URL, path: String) throws {
        let baseURL = cloneA.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: baseURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("base".utf8).write(to: baseURL)
        _ = try shell([gitURL.path, "-C", cloneA.path, "add", path])
        _ = try shell([gitURL.path, "-C", cloneA.path, "commit", "-m", "Add base for conflict"])
        _ = try shell([gitURL.path, "-C", cloneA.path, "push", "origin", "HEAD"])

        _ = try shell([gitURL.path, "-C", cloneB.path, "pull", "--ff-only"])

        try Data("local-change".utf8).write(to: baseURL)
        _ = try shell([gitURL.path, "-C", cloneA.path, "add", path])
        _ = try shell([gitURL.path, "-C", cloneA.path, "commit", "-m", "Local conflicting change"])

        let remoteURL = cloneB.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: remoteURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("remote-change".utf8).write(to: remoteURL)
        _ = try shell([gitURL.path, "-C", cloneB.path, "add", path])
        _ = try shell([gitURL.path, "-C", cloneB.path, "commit", "-m", "Remote conflicting change"])
        _ = try shell([gitURL.path, "-C", cloneB.path, "push", "origin", "HEAD"])
    }

    func tearDown() throws {
        if let gpgconfURL {
            _ = try? shell(
                [gpgconfURL.path, "--homedir", gnupgHome.path, "--kill", "all"],
                env: composedEnv()
            )
        }

        if FileManager.default.fileExists(atPath: workDir.path) {
            try FileManager.default.removeItem(at: workDir)
        }
    }

    private func configureGitIdentity(in repoDir: URL) throws {
        _ = try shell([gitURL.path, "-C", repoDir.path, "config", "user.email", "e2e@kizba.local"])
        _ = try shell([gitURL.path, "-C", repoDir.path, "config", "user.name", "Kizba E2E"])
        _ = try shell([gitURL.path, "-C", repoDir.path, "config", "pull.rebase", "false"])
    }

    private func createEphemeralKey(identity: String) throws {
        let existing = try? shell(
            [gpgURL.path, "--batch", "--list-secret-keys", "--with-colons", identity],
            env: composedEnv()
        )
        if existing?.stdout.contains("fpr:") == true {
            return
        }

        let recipe = """
        Key-Type: EDDSA
        Key-Curve: ed25519
        Subkey-Type: ECDH
        Subkey-Curve: cv25519
        Name-Real: Kizba E2E
        Name-Email: \(identity)
        Expire-Date: 1d
        %no-protection
        %commit

        """

        let keyInputFile = workDir.appendingPathComponent("gpg-key-input", isDirectory: false)
        try Data(recipe.utf8).write(to: keyInputFile)
        defer { try? FileManager.default.removeItem(at: keyInputFile) }

        _ = try shell(
            [gpgURL.path, "--batch", "--gen-key", keyInputFile.path],
            env: composedEnv(),
            timeoutSeconds: 90
        )
    }

    private func composedEnv(additions: [String: String] = [:]) -> [String: String] {
        var env: [String: String] = [
            "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "GNUPGHOME": gnupgHome.path,
            "LC_ALL": "C",
            "LANG": "C",
        ]
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            env["HOME"] = home
        }
        for (key, value) in additions {
            env[key] = value
        }
        return env
    }

    private static func sanitize(_ value: String) -> String {
        var result = value
        result = result.replacingOccurrences(
            of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            with: "[REDACTED_EMAIL]",
            options: [.regularExpression, .caseInsensitive]
        )
        result = result.replacingOccurrences(
            of: #"\b[0-9A-Fa-f]{8,}\b"#,
            with: "[REDACTED_HEX]",
            options: [.regularExpression]
        )
        return result
    }

    private static func resolveBinary(named name: String) throws -> URL {
        if let url = resolveBinaryIfPresent(named: name) {
            return url
        }
        throw HelperError.missingBinary(name)
    }

    private static func resolveBinaryIfPresent(named name: String) -> URL? {
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "/usr/bin/\(name)",
            "/bin/\(name)",
        ]

        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}
