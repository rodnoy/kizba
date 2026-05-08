import Foundation
import XCTest
@testable import Kizba

final class ReleaseBinaryTests: XCTestCase {
    func testDebugFixturesAbsentFromReleaseDescription() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // KizbaTests/
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("Kizba/Infrastructure/Pass/MockPassManager.swift")

        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

        func isSkippable(_ s: Substring) -> Bool {
            let t = s.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { return true }
            if t.hasPrefix("//") { return true }
            if t.hasPrefix("/*") { return true }
            return false
        }

        guard let first = lines.first(where: { !isSkippable($0) })?.trimmingCharacters(in: .whitespaces) else {
            XCTFail("MockPassManager.swift is empty or only comments")
            return
        }
        XCTAssertEqual(first, "#if DEBUG", "MockPassManager.swift must start with #if DEBUG")

        guard let last = lines.reversed().first(where: { !isSkippable($0) })?.trimmingCharacters(in: .whitespaces) else {
            XCTFail("MockPassManager.swift is empty or only comments")
            return
        }
        XCTAssertEqual(last, "#endif", "MockPassManager.swift must end with #endif")
    }
}
