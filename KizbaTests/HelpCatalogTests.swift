//
//  HelpCatalogTests.swift
//  KizbaTests
//
//  Shape assertions for ``HelpCatalog``. Locks the AEAD/MDC
//  compatibility topic against the design document — section count,
//  headings, deterministic block ids, non-empty payloads — so a
//  copy edit cannot silently drop a step or scramble the wording.
//

import XCTest
@testable import Kizba

final class HelpCatalogTests: XCTestCase {

    // MARK: - Catalog-level shape

    func testCatalog_hasAtLeastOneTopic() {
        XCTAssertFalse(HelpCatalog.all.isEmpty)
    }

    func testCatalog_topicIDsAreUnique() {
        let ids = HelpCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Duplicate topic ids: \(ids)")
    }

    func testCatalog_aeadTopicExistsByID() {
        XCTAssertNotNil(
            HelpCatalog.all.first(where: { $0.id == "aead-mdc-compatibility" }),
            "Catalog must contain the AEAD/MDC compatibility topic by id"
        )
        // The typed accessor must round-trip to the same id.
        XCTAssertEqual(
            HelpCatalog.aeadMDCCompatibility.id,
            "aead-mdc-compatibility"
        )
    }

    // MARK: - AEAD topic shape

    func testCatalog_aeadTopic_hasExpectedSectionCount() {
        XCTAssertEqual(HelpCatalog.aeadMDCCompatibility.sections.count, 7)
    }

    func testCatalog_aeadTopic_sectionHeadingsMatchSpec() {
        let expected: [String] = [
            "What's happening",
            "Symptoms",
            "Step 1 — Back up your key (recommended)",
            "Step 2 — Remove AEAD from key preferences",
            "Step 3 — Verify the fix",
            "Step 4 — Re-encrypt existing AEAD files",
            "Step 5 — Sync the public key to other devices",
        ]
        XCTAssertEqual(
            HelpCatalog.aeadMDCCompatibility.sections.map(\.heading),
            expected
        )
    }

    func testCatalog_aeadTopic_everyCommandIsNonEmpty() {
        for section in HelpCatalog.aeadMDCCompatibility.sections {
            for block in section.body {
                if case let .command(_, _, command, _) = block {
                    XCTAssertFalse(
                        command.isEmpty,
                        "Empty `command` in section \(section.id)"
                    )
                }
            }
        }
    }

    func testCatalog_aeadTopic_everyCommandSequenceHasAtLeastOneCommand() {
        for section in HelpCatalog.aeadMDCCompatibility.sections {
            for block in section.body {
                if case let .commandSequence(_, _, commands, _) = block {
                    XCTAssertFalse(
                        commands.isEmpty,
                        "Empty commandSequence in section \(section.id)"
                    )
                    for line in commands {
                        XCTAssertFalse(
                            line.isEmpty,
                            "Empty line inside commandSequence in section \(section.id)"
                        )
                    }
                }
            }
        }
    }

    func testCatalog_aeadTopic_blockIDsAreUniqueWithinTopic() {
        let topic = HelpCatalog.aeadMDCCompatibility
        let allBlockIDs = topic.sections.flatMap { $0.body.map(\.id) }
        XCTAssertEqual(
            Set(allBlockIDs).count,
            allBlockIDs.count,
            "Duplicate block ids inside topic \(topic.id): \(allBlockIDs)"
        )
    }

    func testCatalog_aeadTopic_paragraphsAreNonEmpty() {
        for section in HelpCatalog.aeadMDCCompatibility.sections {
            for block in section.body {
                if case let .paragraph(_, text) = block {
                    XCTAssertFalse(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        "Empty paragraph in section \(section.id)"
                    )
                }
            }
        }
    }

    func testCatalog_aeadTopic_warningsAreNonEmpty() {
        for section in HelpCatalog.aeadMDCCompatibility.sections {
            for block in section.body {
                if case let .warning(_, text) = block {
                    XCTAssertFalse(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        "Empty warning in section \(section.id)"
                    )
                }
            }
        }
    }

    // MARK: - D1 anchor: discovery script uses `find`, not bash globstar

    /// The Section 6 discovery script must not regress to bash
    /// globstar (which fails on default macOS bash 3.2 / zsh).
    /// Locks the `find ... -name '*.gpg' -type f` pivot so a future
    /// edit cannot silently reintroduce the broken form.
    func testCatalog_aeadTopic_section6_findScriptUsesFind() {
        let topic = HelpCatalog.aeadMDCCompatibility
        XCTAssertGreaterThan(topic.sections.count, 5)
        let section6 = topic.sections[5]

        // First commandSequence in the section is the discovery script.
        let firstSequence = section6.body.compactMap { block -> [String]? in
            if case let .commandSequence(_, _, commands, _) = block {
                return commands
            }
            return nil
        }.first

        guard let commands = firstSequence else {
            XCTFail("Section 6 must contain a commandSequence (discovery script)")
            return
        }
        XCTAssertEqual(commands.count, 5, "Discovery script must be 5 lines")
        XCTAssertEqual(
            commands.first,
            "find ~/.password-store -name '*.gpg' -type f | while read f; do"
        )
        // Ensure no globstar form sneaks back.
        let joined = commands.joined(separator: "\n")
        XCTAssertFalse(
            joined.contains("**/*.gpg"),
            "Discovery script must not use bash globstar; use `find` instead"
        )
    }
}
