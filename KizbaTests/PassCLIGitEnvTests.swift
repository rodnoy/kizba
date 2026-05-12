import XCTest
@testable import Kizba

final class PassCLIGitEnvTests: XCTestCase {

    private static let passURL = URL(fileURLWithPath: "/opt/homebrew/bin/pass")

    func testGitEnv_containsGitTerminalPromptZero() {
        let cli = makeCLI()

        let env = cli.composedGitEnvironment()

        XCTAssertEqual(env["GIT_TERMINAL_PROMPT"], "0")
    }

    func testGitEnv_containsSshAskpassFalse() {
        let cli = makeCLI()

        let env = cli.composedGitEnvironment()

        XCTAssertEqual(env["SSH_ASKPASS"], "/usr/bin/false")
    }

    func testGitEnv_propagatesSshAuthSock_whenPresent() {
        withTemporaryEnvironmentValue(key: "SSH_AUTH_SOCK", value: "/tmp/kizba-agent.sock") {
            let cli = makeCLI()

            let env = cli.composedGitEnvironment()

            XCTAssertEqual(env["SSH_AUTH_SOCK"], "/tmp/kizba-agent.sock")
        }
    }

    func testGitEnv_omitsSshAuthSock_whenAbsent() {
        withTemporaryEnvironmentValue(key: "SSH_AUTH_SOCK", value: nil) {
            let cli = makeCLI()

            let env = cli.composedGitEnvironment()

            XCTAssertNil(env["SSH_AUTH_SOCK"])
        }
    }

    func testGitEnv_inheritsBaseComposedEnv() {
        let cli = makeCLI(
            passwordStoreDir: URL(fileURLWithPath: "/tmp/kizba-store"),
            homeOverride: "/tmp/kizba-home"
        )

        let env = cli.composedGitEnvironment()

        // PATH is the default composed PATH plus `/sbin:/usr/sbin`
        // appended for the `pass`/`darwin.sh` RAM-disk helpers (Fix 3).
        XCTAssertEqual(env["PATH"], PassCLI.defaultPATH + ":/sbin:/usr/sbin")
        XCTAssertEqual(env["PASSWORD_STORE_DIR"], "/tmp/kizba-store")
        XCTAssertEqual(env["HOME"], "/tmp/kizba-home")
    }

    // MVP4 fix-pack v1, Fix 3 — `pass git pull/push` invokes
    // `darwin.sh` which calls `umount` (`/sbin`) and `diskutil`
    // (`/usr/sbin`). Both directories MUST appear on the child's PATH
    // for git operations or the operation fails silently with a
    // "command not found" deep inside the helper.
    func testGitEnv_pathIncludesSbinAndUsrSbin() {
        let cli = makeCLI()

        let env = cli.composedGitEnvironment()
        let path = env["PATH"] ?? ""
        let parts = path.split(separator: ":").map(String.init)

        XCTAssertTrue(parts.contains("/sbin"), "PATH should include /sbin: \(path)")
        XCTAssertTrue(parts.contains("/usr/sbin"), "PATH should include /usr/sbin: \(path)")
    }

    private func makeCLI(
        passwordStoreDir: URL? = nil,
        homeOverride: String? = nil
    ) -> PassCLI {
        PassCLI(
            executable: Self.passURL,
            shellRunner: FakeShellRunner(),
            passwordStoreDir: passwordStoreDir,
            homeOverride: homeOverride
        )
    }

    private func withTemporaryEnvironmentValue(key: String, value: String?, perform: () -> Void) {
        let original = ProcessInfo.processInfo.environment[key]
        if let value {
            setenv(key, value, 1)
        } else {
            unsetenv(key)
        }

        defer {
            if let original {
                setenv(key, original, 1)
            } else {
                unsetenv(key)
            }
        }

        perform()
    }
}
