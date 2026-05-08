import XCTest
@testable import Kizba

final class AppInfoTests: XCTestCase {
    func testVersionIsNotEmpty() throws {
        let v = AppInfo.version.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(v.isEmpty, "AppInfo.version should not be empty")
    }

    func testBuildIsNotEmpty() throws {
        let b = AppInfo.build.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(b.isEmpty, "AppInfo.build should not be empty")
    }
}
