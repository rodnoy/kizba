import XCTest

final class CodeReviewChecklistExistsTests: XCTestCase {
    func testCodeReviewChecklistExists() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // KizbaTests/
            .deletingLastPathComponent() // repo root
        let checklist = repoRoot.appendingPathComponent(".ai/code-review-checklist.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: checklist.path))
    }
}
