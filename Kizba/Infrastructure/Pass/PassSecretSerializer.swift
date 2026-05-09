//
//  PassSecretSerializer.swift
//  Kizba
//
//  Inverse of `PassShowParser`. Produces the multiline body to feed
//  `pass insert -m` via stdin (Phase D.3 / 4.x).
//
//  Strictly IO-free: no shell, no FileManager, no logging. The output
//  contains the cleartext password and must never be printed, logged
//  or otherwise persisted by callers.
//

import Foundation

/// Pure serializer that turns a ``PassSecret`` (or its mutable
/// ``SecretDraft`` companion) into the multiline body consumed by
/// `pass insert -m`. Inverse of ``PassShowParser`` at the value level.
///
/// Output format:
///
///     <password>\n
///     <key1>: <value1>\n
///     <key2>: <value2>\n
///     ...
///     <notes-verbatim>
///
/// Rules enforced by this type:
/// - Exactly one `\n` terminates the password line.
/// - Each metadata pair is rendered as `"<key>: <value>\n"` with a
///   single space after the colon. Pair order is preserved, including
///   duplicate keys.
/// - Notes are appended verbatim — no leading separator (no blank
///   line) is inserted before them and no trailing newline is added by
///   the serializer. If the user-supplied notes already end in `\n`,
///   that newline is kept.
/// - Empty notes (empty string or `nil`) emit no notes block at all.
/// - A secret with no metadata and no notes serialises to exactly
///   `"<password>\n"`.
///
/// **Round-trip contract**:
/// `PassShowParser.parse(PassSecretSerializer.serialize(s))` produces
/// a result whose component values match `s` for every `PassSecret`
/// whose `notes` does **not** begin with a line matching the regex
/// `/^[A-Za-z0-9_.-]+:\s/`.
///
/// **Known limitation**: secrets whose `notes` begin with such a
/// "key: value"-shaped line cannot round-trip — on re-parse, that
/// leading line is indistinguishable from a metadata entry and will
/// be promoted into the metadata block. This is inherited from the
/// informal `pass` body format itself; there is no in-band escape.
/// Phase F's `MetadataValidator` is expected to surface the situation
/// as a form-time warning so the user can adjust the notes prefix
/// (e.g. by inserting a leading blank line) before saving.
public enum PassSecretSerializer {

    /// Serialises a fully-formed ``PassSecret``.
    ///
    /// See the type-level documentation for the format and the
    /// round-trip contract / known limitation around notes that begin
    /// with a `key: value`-shaped line.
    public static func serialize(_ secret: PassSecret) -> String {
        render(
            password: secret.password,
            fields: secret.metadata.fields,
            notes: secret.metadata.notes
        )
    }

    /// Convenience overload for the mutable form draft.
    ///
    /// Equivalent to `serialize(draft.snapshot())`: the draft's notes
    /// field is treated the same as `nil` when empty, matching
    /// ``SecretDraft/snapshot()``'s behaviour.
    public static func serialize(_ draft: SecretDraft) -> String {
        let fields = draft.metadata.map {
            PassMetadata.Field(key: $0.key, value: $0.value)
        }
        let notes: String? = draft.notes.isEmpty ? nil : draft.notes
        return render(password: draft.password, fields: fields, notes: notes)
    }

    // MARK: - Implementation

    /// Single rendering routine shared by both public overloads. Kept
    /// private so the format stays defined in one place.
    private static func render(
        password: String,
        fields: [PassMetadata.Field],
        notes: String?
    ) -> String {
        var out = ""
        // Rough capacity hint: password + newline + per-field overhead
        // + notes. Avoids repeated reallocations on typical entries.
        let metadataEstimate = fields.reduce(0) { acc, f in
            acc + f.key.utf8.count + f.value.utf8.count + 3 // ": " + "\n"
        }
        out.reserveCapacity(
            password.utf8.count + 1 + metadataEstimate + (notes?.utf8.count ?? 0)
        )

        out.append(password)
        out.append("\n")

        for field in fields {
            out.append(field.key)
            out.append(": ")
            out.append(field.value)
            out.append("\n")
        }

        // Treat nil and "" identically: emit nothing.
        if let notes, !notes.isEmpty {
            out.append(notes)
        }

        return out
    }
}
