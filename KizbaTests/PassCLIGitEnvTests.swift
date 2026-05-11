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

        XCTAssertEqual(env["PATH"], PassCLI.defaultPATH)
        XCTAssertEqual(env["PASSWORD_STORE_DIR"], "/tmp/kizba-store")
        XCTAssertEqual(env["HOME"], "/tmp/kizba-home")
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
