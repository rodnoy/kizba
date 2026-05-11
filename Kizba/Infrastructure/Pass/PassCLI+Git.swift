import Foundation

public extension PassCLI {

    func gitStatus(storePath: String, gitExecutable: URL) async throws -> GitStatus {
        let invocation = ShellInvocation(
            executable: gitExecutable,
            arguments: ["-C", storePath, "status", "--porcelain=v2", "--branch"],
            environment: composedGitEnvironment(),
            stdin: .none,
            timeout: .seconds(5)
        )

        let result = try await shellRunner.run(invocation)
        if result.exitCode != 0 {
            let stderr = String(data: result.standardError, encoding: .utf8) ?? ""
            let mapped = PassGitErrorMapper.map(stderr: stderr, exitCode: result.exitCode, operation: .status)
            if mapped.error == .gitNotInitialized {
                return .notARepository
            }
            throw mapped.error
        }

        let stdout = String(data: result.standardOutput, encoding: .utf8) ?? ""
        let parsed = GitStatusParser.parse(stdout)
        let fetchHeadPath = URL(fileURLWithPath: storePath)
            .appendingPathComponent(".git", isDirectory: true)
            .appendingPathComponent("FETCH_HEAD")

        let lastFetchAt: Date?
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fetchHeadPath.path),
           let date = attributes[.modificationDate] as? Date {
            lastFetchAt = date
        } else {
            lastFetchAt = nil
        }

        return GitStatus(
            isGitRepository: true,
            branch: parsed.branch,
            hasLocalChanges: parsed.hasLocalChanges,
            hasConflicts: parsed.hasConflicts,
            aheadCount: parsed.aheadCount,
            behindCount: parsed.behindCount,
            hasRemote: parsed.hasRemote,
            lastFetchAt: lastFetchAt
        )
    }

    func gitPull(storePath: String, timeoutSeconds: Int) async throws {
        var environment = composedGitEnvironment()
        environment["PASSWORD_STORE_DIR"] = storePath

        let invocation = ShellInvocation(
            executable: executable,
            arguments: ["git", "pull"],
            environment: environment,
            stdin: .none,
            timeout: .seconds(timeoutSeconds)
        )

        let result = try await shellRunner.run(invocation)
        if result.exitCode != 0 {
            let stderr = String(data: result.standardError, encoding: .utf8) ?? ""
            let mapped = PassGitErrorMapper.map(stderr: stderr, exitCode: result.exitCode, operation: .pull)
            throw mapped.error
        }
    }

    func gitPush(storePath: String, timeoutSeconds: Int) async throws -> GitPushOutcome {
        var environment = composedGitEnvironment()
        environment["PASSWORD_STORE_DIR"] = storePath

        let invocation = ShellInvocation(
            executable: executable,
            arguments: ["git", "push"],
            environment: environment,
            stdin: .none,
            timeout: .seconds(timeoutSeconds)
        )

        let result = try await shellRunner.run(invocation)
        if result.exitCode != 0 {
            let stderr = String(data: result.standardError, encoding: .utf8) ?? ""
            let mapped = PassGitErrorMapper.map(stderr: stderr, exitCode: result.exitCode, operation: .push)
            throw mapped.error
        }

        let stdout = String(data: result.standardOutput, encoding: .utf8) ?? ""
        let stderr = String(data: result.standardError, encoding: .utf8) ?? ""
        let combined = "\(stdout)\n\(stderr)".lowercased()

        if combined.contains("everything up-to-date") || combined.contains("up to date") {
            return .alreadyUpToDate
        }
        return .pushed
    }

    internal func composedGitEnvironment() -> [String: String] {
        var env = composedEnvironment()
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["SSH_ASKPASS"] = "/usr/bin/false"
        if let sshAuthSock = ProcessInfo.processInfo.environment["SSH_AUTH_SOCK"] {
            env["SSH_AUTH_SOCK"] = sshAuthSock
        } else {
            env.removeValue(forKey: "SSH_AUTH_SOCK")
        }
        return env
    }
}
