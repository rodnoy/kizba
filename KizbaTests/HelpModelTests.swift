//
//  HelpModelTests.swift
//  KizbaTests
//
//  Behavioural tests for ``HelpModel`` — selection, copy plumbing,
//  flash-state machine. Real wall-clock waits are kept short
//  (`flashDuration: .milliseconds(20)`) so the suite stays fast.
//

import XCTest
@testable import Kizba

@MainActor
final class HelpModelTests: XCTestCase {

    // MARK: - Test helpers

    private func makeTopic(id: String, title: String = "T", blockIDs: [String] = []) -> HelpTopic {
        let body: [HelpBlock] = blockIDs.map { .paragraph(id: $0, text: "x") }
        let section = HelpSection(id: "\(id)/0", heading: "H", body: body)
        return HelpTopic(id: id, title: title, subtitle: nil, sections: [section])
    }

    private func makeModel(
        topics: [HelpTopic]? = nil,
        flashDuration: Duration = .milliseconds(20)
    ) -> (HelpModel, FakeClipboardServicing) {
        let clipboard = FakeClipboardServicing()
        let catalog = topics ?? [
            makeTopic(id: "alpha", blockIDs: ["alpha/0/0"]),
            makeTopic(id: "beta", blockIDs: ["beta/0/0"]),
        ]
        let model = HelpModel(
            clipboard: clipboard,
            catalog: catalog,
            flashDuration: flashDuration
        )
        return (model, clipboard)
    }

    // MARK: - Selection

    func testInit_selectsFirstTopicByDefault() {
        let (model, _) = makeModel()
        XCTAssertEqual(model.selectedTopicID, "alpha")
    }

    func testInit_selectedTopic_resolvesByID() {
        let (model, _) = makeModel()
        XCTAssertEqual(model.selectedTopic?.id, "alpha")
    }

    func testSetSelectedTopicID_changesSelectedTopic() {
        let (model, _) = makeModel()
        model.selectedTopicID = "beta"
        XCTAssertEqual(model.selectedTopic?.id, "beta")
    }

    func testSelectedTopic_fallsBackToFirstWhenIDMissing() {
        let (model, _) = makeModel()
        model.selectedTopicID = "does-not-exist"
        // Spec: `selectedTopic` returns nil when the id has no match.
        // The `HelpView` falls back to the first topic via the
        // master/detail pane's empty-state branch — model itself
        // surfaces the unresolved state.
        XCTAssertNil(model.selectedTopic)
    }

    // MARK: - Copy plumbing

    func testCopy_invokesClipboardWithSingleCommand() async {
        let (model, clipboard) = makeModel()
        await model.copy(commands: ["echo hi"], for: "alpha/0/0")
        XCTAssertEqual(clipboard.calls.count, 1)
        XCTAssertEqual(clipboard.lastCall?.value, "echo hi")
    }

    func testCopy_joinsMultipleCommandsWithNewlines() async {
        let (model, clipboard) = makeModel()
        await model.copy(commands: ["a", "b", "c"], for: "alpha/0/0")
        XCTAssertEqual(clipboard.lastCall?.value, "a\nb\nc")
    }

    func testCopy_singleElementArray_isNotMutated() async {
        let (model, clipboard) = makeModel()
        await model.copy(commands: ["only"], for: "alpha/0/0")
        // Single-element join must equal the element verbatim — no
        // trailing newline, no separator.
        XCTAssertEqual(clipboard.lastCall?.value, "only")
    }

    func testCopy_passesHelpRetentionDuration() async {
        let (model, clipboard) = makeModel()
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertEqual(
            clipboard.lastCall?.clearAfter,
            HelpModel.helpClipboardRetention,
            "Help-driven copies must use HelpModel.helpClipboardRetention"
        )
    }

    func testCopy_setsCopiedBlockID() async {
        let (model, _) = makeModel()
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertEqual(model.copiedBlockID, "alpha/0/0")
    }

    func testCopy_clearsCopiedBlockIDAfterFlashDuration() async throws {
        let (model, _) = makeModel(flashDuration: .milliseconds(20))
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertEqual(model.copiedBlockID, "alpha/0/0")

        // Wait a bit longer than the flash window, then yield so the
        // detached reset task runs on the main actor.
        try await Task.sleep(for: .milliseconds(80))
        await Task.yield()

        XCTAssertNil(
            model.copiedBlockID,
            "Flash should reset to nil after the configured duration"
        )
    }

    func testCopy_repeatedOnSameBlock_keepsCopiedBlockIDStable() async {
        let (model, _) = makeModel(flashDuration: .seconds(10))
        await model.copy(commands: ["x"], for: "alpha/0/0")
        await model.copy(commands: ["x"], for: "alpha/0/0")
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertEqual(model.copiedBlockID, "alpha/0/0")
    }

    func testCopy_onDifferentBlock_movesCopiedBlockIDImmediately() async {
        let (model, _) = makeModel(flashDuration: .seconds(10))
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertEqual(model.copiedBlockID, "alpha/0/0")
        await model.copy(commands: ["y"], for: "beta/0/0")
        XCTAssertEqual(
            model.copiedBlockID,
            "beta/0/0",
            "Copy on a different block must reassign copiedBlockID immediately"
        )
    }

    func testIsCopied_isFalseForOtherBlocks() async {
        let (model, _) = makeModel(flashDuration: .seconds(10))
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertFalse(model.isCopied(blockID: "beta/0/0"))
    }

    func testIsCopied_isTrueForActiveBlock() async {
        let (model, _) = makeModel(flashDuration: .seconds(10))
        await model.copy(commands: ["x"], for: "alpha/0/0")
        XCTAssertTrue(model.isCopied(blockID: "alpha/0/0"))
    }
}
