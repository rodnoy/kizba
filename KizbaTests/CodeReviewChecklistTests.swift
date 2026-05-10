import XCTest

class CodeReviewChecklistTests: XCTestCase {
    func testChecklistExists() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: ".ai/code-review-checklist.md"))
    }
}
