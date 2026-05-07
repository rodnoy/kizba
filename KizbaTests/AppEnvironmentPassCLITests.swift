//
//  AppEnvironmentPassCLITests.swift
//  KizbaTests
//
//  Step 5.3 — verify `AppEnvironment.live()` wires a `LivePassCLI`
//  that delegates to an injected `BinaryLocating`. No external
//  binaries are invoked: discovery is exercised separately and
//  `LivePassCLI` resolution is tested against a fake locator.
//

#if DEBUG

import XCTest
@testable import Kizba

final class AppEnvironmentPassCLITests: XCTestCase {

    func testLive_includesPassCLI() {
        let env = AppEnvironment.live()
        XCTAssertNotNil(env.passCLI, "live() must wire a LivePassCLI instance.")
    }

    func testPreview_doesNotIncludePassCLI() {
        let env = AppEnvironment.preview()
        XCTAssertNil(env.passCLI, "preview() must keep passCLI nil to avoid touching real binaries.")
    }

    func testLive_passCLIWiresBinaryDiscoveryService() async {
        let env = AppEnvironment.live()
        let cli = try? XCTUnwrap(env.passCLI)
        guard let cli else { return XCTFail("passCLI missing") }

        // Reach through the actor to confirm the wired discovery is the
        // real `BinaryDiscoveryService` type from Phase 5.1.
        let discovery = await cli.discovery
        XCTAssertTrue(
            discovery is BinaryDiscoveryService,
            "live() must wire BinaryDiscoveryService, got \(type(of: discovery))."
        )
    }

    func testLivePassCLI_throwsBinaryNotFoundWhenDiscoveryReturnsNil() async {
        let locator = NilBinaryLocator()
        let runner = NeverCalledShellRunner()
        let cli = LivePassCLI(discovery: locator, shellRunner: runner)

        do {
            _ = try await cli.show(entryPath: "any/entry")
            XCTFail("Expected PassError.binaryNotFound")
        } catch let error as PassError {
            switch error {
            case .binaryNotFound(let name):
                XCTAssertEqual(name, BinaryName.pass.rawValue)
            default:
                XCTFail("Unexpected PassError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test doubles

private actor NilBinaryLocator: BinaryLocating {
    func locate(_ binary: BinaryName) async -> URL? { nil }
    func reDetect() async {}
}

private struct NeverCalledShellRunner: ShellCommandRunning {
    func run(
        executable: URL,
        arguments: [String],
        environment: [String: String],
        timeout: Duration
    ) async throws -> ShellResult {
        XCTFail("Shell runner must not be invoked when discovery fails.")
        throw PassError.shellFailure(exitCode: -1, stderrExcerpt: "unreachable")
    }
}

#endif
