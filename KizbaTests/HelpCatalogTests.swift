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

    // MARK: - Phase E setup topics — presence + shape

    func testCatalog_containsSetupPassAndGPGTopic() {
        XCTAssertNotNil(
            HelpCatalog.all.first(where: { $0.id == "setup-pass-and-gpg" }),
            "Catalog must contain the pass-store / GPG setup topic by id"
        )
    }

    func testCatalog_containsSetupGitRemoteTopic() {
        XCTAssertNotNil(
            HelpCatalog.all.first(where: { $0.id == "setup-git-remote" }),
            "Catalog must contain the git-remote setup topic by id"
        )
    }

    func testCatalog_containsConfigurePinentryTopic() {
        XCTAssertNotNil(
            HelpCatalog.all.first(where: { $0.id == "configure-pinentry" }),
            "Catalog must contain the pinentry-mac configuration topic by id"
        )
    }

    func testSetupTopics_haveAccessors() {
        XCTAssertEqual(HelpCatalog.setupPassAndGPG.id, "setup-pass-and-gpg")
        XCTAssertEqual(HelpCatalog.setupGitRemote.id, "setup-git-remote")
        XCTAssertEqual(HelpCatalog.configurePinentry.id, "configure-pinentry")
    }

    func testSetupTopics_haveExpectedSectionCount() {
        // Each setup topic ships ~5 sections by design (4...6 acceptable).
        for topic in [
            HelpCatalog.setupPassAndGPG,
            HelpCatalog.setupGitRemote,
            HelpCatalog.configurePinentry,
        ] {
            XCTAssertTrue(
                (4...6).contains(topic.sections.count),
                "Topic \(topic.id) should ship 4-6 sections, got \(topic.sections.count)"
            )
        }
    }

    func testSetupTopics_containCommandAndWarningBlocks() {
        // Setup topics must mix at least one command-style block
        // (.command or .commandSequence) with at least one .warning
        // so users get both actionable steps and explicit pitfalls.
        for topic in [
            HelpCatalog.setupPassAndGPG,
            HelpCatalog.setupGitRemote,
            HelpCatalog.configurePinentry,
        ] {
            let allBlocks = topic.sections.flatMap(\.body)
            let hasCommand = allBlocks.contains { block in
                switch block {
                case .command, .commandSequence: return true
                default: return false
                }
            }
            let hasWarning = allBlocks.contains { block in
                if case .warning = block { return true }
                return false
            }
            XCTAssertTrue(hasCommand, "Topic \(topic.id) must contain at least one command block")
            XCTAssertTrue(hasWarning, "Topic \(topic.id) must contain at least one warning block")
        }
    }

    func testSetupTopics_blockIDsAreUniqueWithinTopic() {
        for topic in [
            HelpCatalog.setupPassAndGPG,
            HelpCatalog.setupGitRemote,
            HelpCatalog.configurePinentry,
        ] {
            let blockIDs = topic.sections.flatMap { $0.body.map(\.id) }
            XCTAssertEqual(
                Set(blockIDs).count,
                blockIDs.count,
                "Duplicate block ids inside topic \(topic.id): \(blockIDs)"
            )
        }
    }

    func testSetupTopics_everyCommandIsNonEmpty() {
        for topic in [
            HelpCatalog.setupPassAndGPG,
            HelpCatalog.setupGitRemote,
            HelpCatalog.configurePinentry,
        ] {
            for section in topic.sections {
                for block in section.body {
                    switch block {
                    case let .command(_, _, command, _):
                        XCTAssertFalse(
                            command.isEmpty,
                            "Empty command in \(section.id)"
                        )
                    case let .commandSequence(_, _, commands, _):
                        XCTAssertFalse(
                            commands.isEmpty,
                            "Empty commandSequence in \(section.id)"
                        )
                        for line in commands {
                            XCTAssertFalse(
                                line.isEmpty,
                                "Empty line in commandSequence in \(section.id)"
                            )
                        }
                    default:
                        break
                    }
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
