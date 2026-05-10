import XCTest

class CodeReviewChecklistTests: XCTestCase {
    func testChecklistExists() {
        let envSrcroot = ProcessInfo.processInfo.environment["SRCROOT"] ?? ""
        let cwd = FileManager.default.currentDirectoryPath
        let candidates = [
            envSrcroot.isEmpty ? nil : envSrcroot + "/.ai/code-review-checklist.md",
            cwd + "/.ai/code-review-checklist.md",
            cwd + "/../.ai/code-review-checklist.md",
            cwd + "/../../.ai/code-review-checklist.md",
        ].compactMap { $0 }

        var foundPath: String?
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) {
                foundPath = path
                break
            }
        }

        if foundPath == nil {
            XCTFail("Could not find .ai/code-review-checklist.md at any of the following paths:\n\(candidates.joined(separator: "\n"))")
        }
    }
}
