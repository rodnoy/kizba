//
//  PassSecretExporter.swift
//  Kizba
//
//  Pure bridge from the domain (``PassEntry`` + ``PassSecret``) pair
//  to the portable ``ExportRecord`` DTO consumed by the exporters in
//  this directory.
//
//  Lives in Infrastructure (not Domain) because the destination DTO
//  is itself an Infrastructure-tier concept — the domain never sees
//  ``ExportRecord``. The conversion is total (no failures) and
//  pure: no I/O, no shell, no main-actor hops.
//

import Foundation

public enum PassSecretExporter {

    /// Metadata keys (compared case-insensitively) that map onto
    /// first-class ``ExportRecord`` fields. Every other metadata
    /// field is preserved verbatim under ``ExportRecord/extraFields``.
    private static let mappedKeys: Set<String> = [
        "user", "username", "login",
        "url", "website",
        "otpauth",
    ]

    /// Converts a single (entry, secret) pair into a portable
    /// ``ExportRecord``. Maps the most common metadata aliases onto
    /// the first-class fields and routes everything else through
    /// `extraFields` so the round trip is loss-free for callers that
    /// understand the extras.
    ///
    /// - Note: ``PassMetadata/firstValue(for:)`` is case-SENSITIVE in
    ///   the production type, so we walk the field list ourselves to
    ///   honour the case-insensitive alias resolution expected by
    ///   external password formats (`User` vs `user` vs `USER`).
    public static func toExportRecord(entry: PassEntry, secret: PassSecret) -> ExportRecord {
        let username = firstField(in: secret.metadata, matchingAny: ["user", "username", "login"])
        let url = firstField(in: secret.metadata, matchingAny: ["url", "website"])
        let totp = firstField(in: secret.metadata, matchingAny: ["otpauth"])

        var extras: [String: String] = [:]
        for field in secret.metadata.fields where !mappedKeys.contains(field.key.lowercased()) {
            // Preserve original key casing in the extras map. If the
            // same key appears multiple times, the last value wins —
            // matches the JSON / CSV exporter expectation of unique
            // keys (the source format does not encode duplicates).
            extras[field.key] = field.value
        }

        return ExportRecord(
            path: entry.path,
            password: secret.password,
            username: username,
            url: url,
            notes: secret.metadata.notes,
            totp: totp,
            extraFields: extras
        )
    }

    /// First metadata value whose lowercase key matches any of the
    /// supplied aliases. Returns `nil` when none match.
    private static func firstField(
        in metadata: PassMetadata,
        matchingAny aliases: [String]
    ) -> String? {
        let aliasSet = Set(aliases.map { $0.lowercased() })
        return metadata.fields.first(where: { aliasSet.contains($0.key.lowercased()) })?.value
    }
}
