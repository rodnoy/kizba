#if DEBUG

import XCTest
@testable import Kizba

@MainActor
final class AppEnvironmentGitWiringTests: XCTestCase {

    func testWireGitModel_noDiscovery_doesNotCreateModel() async {
        let environment = AppEnvironment.preview()
        let appState = AppState()

        await environment.wireGitModelIfAvailable(into: appState)

        XCTAssertNil(appState.gitStatusModel)
    }

    func testWireGitModel_gitNotFound_doesNotCreateModel() async {
        let discovery = FakeDiscovery(urls: [.pass: URL(fileURLWithPath: "/usr/bin/pass")])
        let environment = makeEnvironment(discovery: discovery)
        let appState = AppState()

        await environment.wireGitModelIfAvailable(into: appState)

        XCTAssertNil(appState.gitStatusModel)
    }

    func testWireGitModel_createsModel_whenRepo() async throws {
        let discovery = FakeDiscovery(urls: [
            .pass: URL(fileURLWithPath: "/usr/bin/pass"),
            .git: URL(fileURLWithPath: "/usr/bin/git")
        ])
        let environment = makeEnvironment(discovery: discovery)
        let appState = AppState()

        let stdout = try fixture(named: "clean-with-upstream")
        let shellRunner = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(stdout.utf8), stderr: Data())
        )

        await environment.wireGitModelIfAvailable(into: appState, usingShellRunner: shellRunner)

        XCTAssertNotNil(appState.gitStatusModel)
        XCTAssertEqual(appState.gitStatusModel?.status.branch, "main")
        appState.gitStatusModel?.stop()
    }

    private func makeEnvironment(discovery: any BinaryLocating) -> AppEnvironment {
        AppEnvironment(
            passManager: MockPassManager(entries: [], secrets: [:]),
            clipboard: FakeClipboardServicing(),
            settings: AppEnvironment.InMemorySettingsStore(),
            passwordGenerator: LivePasswordGenerator(),
            passCLI: nil,
            discovery: discovery,
            invocationLog: nil
        )
    }

    private func fixture(named name: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let path = root
            .appendingPathComponent("Fixtures/GitStatusFixtures", isDirectory: true)
            .appendingPathComponent("\(name).txt")
        return try String(contentsOf: path, encoding: .utf8)
    }
}

private actor FakeDiscovery: BinaryLocating {
    private let urls: [BinaryName: URL]

    init(urls: [BinaryName: URL]) {
        self.urls = urls
    }

    func locate(_ binary: BinaryName) async -> URL? {
        urls[binary]
    }

    func reDetect() async {}
}

#endif
