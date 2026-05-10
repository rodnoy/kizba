import XCTest

class CodeReviewChecklistTests: XCTestCase {
    func testChecklistExists() {
        let fileManager = FileManager.default

        var attempted: [String] = []

        // Helper to check and record
        func check(_ path: String) -> Bool {
            attempted.append(path)
            return fileManager.fileExists(atPath: path)
        }

        // 1) SRCROOT if provided
        if let srcroot = ProcessInfo.processInfo.environment["SRCROOT"], !srcroot.isEmpty {
            let p = srcroot + "/.ai/code-review-checklist.md"
            if check(p) { return }
        }

        // 2) current working directory and parents up to 10 levels
        let cwd = fileManager.currentDirectoryPath
        if check(cwd + "/.ai/code-review-checklist.md") { return }
        var parent = cwd
        for _ in 1...10 {
            parent = (parent as NSString).deletingLastPathComponent
            if parent.isEmpty { break }
            let p = parent + "/.ai/code-review-checklist.md"
            if check(p) { return }
            // stop if we reached root
            if parent == "/" { break }
        }

        // 3) walk up from the compile-time source file path (#filePath)
        // Use #filePath to get the location of this test source at compile time.
        let sourceFile = "\(#filePath)"
        var sourceDir = (sourceFile as NSString).deletingLastPathComponent
        for _ in 0...10 {
            if sourceDir.isEmpty { break }
            let p = sourceDir + "/.ai/code-review-checklist.md"
            if check(p) { return }
            let next = (sourceDir as NSString).deletingLastPathComponent
            if next == sourceDir { break }
            sourceDir = next
        }

        // If we reached here, none of the candidates existed
        XCTFail("Could not find .ai/code-review-checklist.md at any of the following paths:\n\(attempted.joined(separator: "\n"))")
    }
}
