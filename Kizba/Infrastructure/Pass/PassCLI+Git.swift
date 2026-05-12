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

        // MVP4 fix-pack v1, Fix 5 — `git status --porcelain=v2 --branch`
        // can only tell us about the current branch's UPSTREAM ref. A
        // repo with `git remote add origin ...` but no `-u`-style
        // upstream still allows pull/push (with the remote name spelled
        // out). Issue a separate `git -C <store> remote` to detect
        // ANY configured remote and stitch both signals into one
        // `GitStatus`.
        let remoteNames = (try? await gitListRemotes(storePath: storePath, gitExecutable: gitExecutable)) ?? ""
        let hasRemote = !remoteNames.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return GitStatus(
            isGitRepository: true,
            branch: parsed.branch,
            hasLocalChanges: parsed.hasLocalChanges,
            hasConflicts: parsed.hasConflicts,
            aheadCount: parsed.aheadCount,
            behindCount: parsed.behindCount,
            hasUpstream: parsed.hasUpstream,
            hasRemote: hasRemote,
            lastFetchAt: lastFetchAt
        )
    }

    /// Lists configured git remotes for `storePath`. Returns the raw
    /// stdout (one remote name per line) or empty string when the
    /// repository has none / the call fails. Caller decides what
    /// "empty" means semantically (Fix 5 uses non-empty as the
    /// `hasRemote` signal).
    func gitListRemotes(storePath: String, gitExecutable: URL) async throws -> String {
        let invocation = ShellInvocation(
            executable: gitExecutable,
            arguments: ["-C", storePath, "remote"],
            environment: composedGitEnvironment(),
            stdin: .none,
            timeout: .seconds(5)
        )

        let result = try await shellRunner.run(invocation)
        if result.exitCode != 0 {
            // A non-zero exit here is expected for non-git directories;
            // do NOT throw — empty output already means "no remotes",
            // which is the safe default for the UI.
            return ""
        }

        return String(data: result.standardOutput, encoding: .utf8) ?? ""
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

        // `pass git pull/push` invokes the platform helper script
        // (`darwin.sh` on macOS), which mounts/unmounts a RAM-disk for
        // working-tree decryption. That script reaches for `umount`
        // (`/sbin`) and `diskutil` (`/usr/sbin`) without absolute
        // paths. The default sanitised PATH from ``composedEnvironment``
        // (`/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`) does not
        // include either system directory, so the helper bails out with
        // "command not found" before the actual git operation runs.
        // Append `/sbin:/usr/sbin` here — scoped to git operations
        // ONLY, since `pass show / insert / generate / mv / rm` do not
        // need the RAM-disk lifecycle and we want to keep
        // ``PassCLI/defaultPATH`` minimal.
        let currentPATH = env["PATH"] ?? PassCLI.defaultPATH
        env["PATH"] = currentPATH + ":/sbin:/usr/sbin"

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
