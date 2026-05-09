//
//  PassSecretSerializerTests.swift
//  KizbaTests
//
//  Unit tests for `PassSecretSerializer` (Phase D.3). Pure string-level
//  checks plus a value-level round-trip property against `PassShowParser`.
//  No fixtures from disk, no shell, no IO.
//

import XCTest
@testable import Kizba

final class PassSecretSerializerTests: XCTestCase {

    // MARK: - Direct serialisation output

    func testPasswordOnly_emitsPasswordPlusSingleNewline() {
        let secret = PassSecret(password: "hunter2")
        XCTAssertEqual(PassSecretSerializer.serialize(secret), "hunter2\n")
    }

    func testEmptyPassword_emitsLoneNewline() {
        // Round-trip note: parse(serialize(_)) yields password = "".
        let secret = PassSecret(password: "")
        XCTAssertEqual(PassSecretSerializer.serialize(secret), "\n")
    }

    func testPasswordPlusOneMetadataPair_noNotes() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: nil
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nuser: alice\n"
        )
    }

    func testPasswordPlusTwoMetadataPairs_orderPreserved() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [
                    .init(key: "user", value: "alice"),
                    .init(key: "url",  value: "https://example.test"),
                ],
                notes: nil
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nuser: alice\nurl: https://example.test\n"
        )
    }

    func testDuplicateMetadataKeys_preservedInOrder() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [
                    .init(key: "tag", value: "red"),
                    .init(key: "tag", value: "blue"),
                    .init(key: "tag", value: "green"),
                ],
                notes: nil
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\ntag: red\ntag: blue\ntag: green\n"
        )
    }

    func testPasswordPlusNotes_noMetadata_noLeadingSeparator() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [], notes: "Just a note.")
        )
        // Per spec rule 6: "<P>\n<N>" — no blank-line separator.
        XCTAssertEqual(PassSecretSerializer.serialize(secret), "pw\nJust a note.")
    }

    func testPasswordPlusMetadataPlusNotes() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: "Free-form note line."
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nuser: alice\nFree-form note line."
        )
    }

    func testPasswordPlusMetadataPlusMultiLineNotes() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: "First note line.\nSecond note line."
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nuser: alice\nFirst note line.\nSecond note line."
        )
    }

    func testNotesWithEmbeddedBlankLine_preservedVerbatim() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: "First.\n\nThird, after blank."
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nuser: alice\nFirst.\n\nThird, after blank."
        )
    }

    func testNotesWithTrailingNewline_preservedVerbatim() {
        // Serializer must not strip or add — user's trailing `\n` stays.
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [], notes: "note\n")
        )
        XCTAssertEqual(PassSecretSerializer.serialize(secret), "pw\nnote\n")
    }

    func testEmptyNotesString_treatedAsNoNotes() {
        // PassMetadata.notes is `String?`; verify empty string is
        // emitted identically to `nil` (no notes block at all).
        let withEmpty = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "k", value: "v")],
                notes: ""
            )
        )
        let withNil = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "k", value: "v")],
                notes: nil
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(withEmpty),
            PassSecretSerializer.serialize(withNil)
        )
        XCTAssertEqual(PassSecretSerializer.serialize(withEmpty), "pw\nk: v\n")
    }

    func testMetadataValueContainingColon_preservedVerbatim() {
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [
                    .init(key: "url",   value: "https://x.test:8443/path"),
                    .init(key: "ratio", value: "1:2:3"),
                ],
                notes: nil
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nurl: https://x.test:8443/path\nratio: 1:2:3\n"
        )
    }

    func testMetadataValueWithLeadingTrailingSpaces_notTrimmed() {
        // The serializer must not normalise whitespace — that is the
        // form layer's responsibility (Phase F).
        let secret = PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "  alice  ")],
                notes: nil
            )
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(secret),
            "pw\nuser:   alice  \n"
        )
    }

    // MARK: - SecretDraft overload

    func testDraftOverload_matchesSnapshotSerialisation() {
        let draft = SecretDraft(
            password: "pw",
            metadata: [
                MetadataPair(key: "user", value: "alice"),
                MetadataPair(key: "url",  value: "https://example.test"),
            ],
            notes: "First.\nSecond."
        )
        XCTAssertEqual(
            PassSecretSerializer.serialize(draft),
            PassSecretSerializer.serialize(draft.snapshot())
        )
    }

    func testDraftOverload_emptyNotes_treatedSameAsNil() {
        let draft = SecretDraft(
            password: "pw",
            metadata: [MetadataPair(key: "k", value: "v")],
            notes: ""
        )
        // snapshot() turns "" into nil; both must produce the same body.
        XCTAssertEqual(
            PassSecretSerializer.serialize(draft),
            PassSecretSerializer.serialize(draft.snapshot())
        )
        XCTAssertEqual(PassSecretSerializer.serialize(draft), "pw\nk: v\n")
    }

    // MARK: - Round-trip property

    /// Representative corpus mirroring the variants the form layer is
    /// expected to produce. Kept inline (rather than reaching into
    /// `MockPassManager.fixtures`) so this test file does not depend on
    /// the `#if DEBUG` mock surface.
    private static let roundTripCorpus: [PassSecret] = [
        // Password-only.
        PassSecret(password: "hunter2"),

        // With-metadata-no-notes.
        PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [
                    .init(key: "user", value: "alice"),
                    .init(key: "url",  value: "https://example.test"),
                ],
                notes: nil
            )
        ),

        // With-notes-no-metadata.
        PassSecret(
            password: "pw",
            metadata: PassMetadata(fields: [], notes: "A free-form note.")
        ),

        // With-both.
        PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: "Free-form note line."
            )
        ),

        // Multi-line notes.
        PassSecret(
            password: "diary-key",
            metadata: PassMetadata(
                fields: [],
                notes: "Multi-line\nnotes block\nwith blank line\n\nincluded."
            )
        ),

        // Notes with embedded blank line + metadata.
        PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [.init(key: "user", value: "alice")],
                notes: "First.\n\nThird, after blank."
            )
        ),

        // Metadata value containing `:`.
        PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [
                    .init(key: "url",   value: "https://x.test:8443/path"),
                    .init(key: "ratio", value: "1:2:3"),
                ],
                notes: "After complex urls."
            )
        ),

        // Duplicate metadata keys.
        PassSecret(
            password: "pw",
            metadata: PassMetadata(
                fields: [
                    .init(key: "tag", value: "red"),
                    .init(key: "tag", value: "blue"),
                    .init(key: "tag", value: "green"),
                ],
                notes: nil
            )
        ),
    ]

    func testRoundTrip_parseOfSerialiseEqualsOriginal_overCorpus() throws {
        for (index, secret) in Self.roundTripCorpus.enumerated() {
            let body = PassSecretSerializer.serialize(secret)
            let parsed = try PassShowParser.parse(body)

            XCTAssertEqual(
                parsed.password, secret.password,
                "password mismatch at corpus index \(index)"
            )

            // Metadata: compare as ordered (key, value) sequences,
            // including duplicates.
            let originalFields = secret.metadata.fields.map { ($0.key, $0.value) }
            XCTAssertEqual(
                parsed.metadata.count, originalFields.count,
                "metadata count mismatch at corpus index \(index)"
            )
            for (i, (lhs, rhs)) in zip(parsed.metadata, originalFields).enumerated() {
                XCTAssertEqual(
                    lhs.0, rhs.0,
                    "metadata key mismatch at corpus index \(index), field \(i)"
                )
                XCTAssertEqual(
                    lhs.1, rhs.1,
                    "metadata value mismatch at corpus index \(index), field \(i)"
                )
            }

            // Notes: parser returns `nil` for absent notes; the secret
            // may carry either `nil` or "" — normalise both sides.
            let expectedNotes: String? = {
                guard let n = secret.metadata.notes, !n.isEmpty else { return nil }
                return n
            }()
            XCTAssertEqual(
                parsed.notes, expectedNotes,
                "notes mismatch at corpus index \(index)"
            )
        }
    }

    // MARK: - Known limitation

    func test_roundTrip_notesStartingWithKeyColonValue_isKnownLimitation() throws {
        throw XCTSkip("""
        Inherent limitation of the `pass` informal body format: notes whose first \
        line matches /^[A-Za-z0-9_.-]+: / are indistinguishable from metadata on \
        re-parse. Documented in PassSecretSerializer.swift. MetadataValidator may \
        surface this as a form-time warning in Phase F.
        """)
    }
}
