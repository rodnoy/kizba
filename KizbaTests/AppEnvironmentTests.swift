//
//  AppEnvironmentTests.swift
//  KizbaTests
//
//  Smoke tests for `AppEnvironment.preview()` wiring. Verify the
//  preview environment exposes the deterministic `MockPassManager`
//  fixture corpus and that `show(_:)` returns a known fixture.
//

#if DEBUG

import XCTest
@testable import Kizba

final class AppEnvironmentTests: XCTestCase {

    func testPreview_passManagerExposesFixtureCorpus() async throws {
        let env = AppEnvironment.preview()
        let entries = try await env.passManager.listEntries()

        XCTAssertEqual(entries.count, 20, "preview() must wire the 20-entry fixture corpus.")
        XCTAssertEqual(entries.first?.path, "personal/email/gmail")
        XCTAssertEqual(entries.last?.path,  "archive/services/ftp")
    }

    func testPreview_passManagerShowReturnsKnownFixture() async throws {
        let env = AppEnvironment.preview()
        let entry = PassEntry(path: "work/aws/root")

        let secret = try await env.passManager.show(entry)

        XCTAssertEqual(secret.password, "aws-root-MFA-required")
        XCTAssertEqual(
            secret.metadata.fields.first { $0.key == "user" }?.value,
            "root@example-org.aws"
        )
    }

    func testPreview_passManagerStoreLocationIsStable() async throws {
        let env = AppEnvironment.preview()
        XCTAssertEqual(
            env.passManager.storeLocation(),
            URL(fileURLWithPath: "/tmp/kizba-mock-store")
        )
    }
}

#endif
