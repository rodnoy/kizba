//
//  ExportRecord.swift
//  Kizba
//
//  Local Codable DTO for cross-app password import/export. NOT a
//  first-class long-lived domain type — created on-demand during a
//  single import/export operation and dropped immediately after.
//
//  Security note: this type intentionally carries cleartext password
//  material because import/export is, by definition, a plaintext
//  boundary. It MUST NOT be persisted, logged, or assigned to any
//  long-lived storage. Lifetimes are bounded by a single Settings
//  Data-tab action; references are released once the operation
//  completes.
//

import Foundation

/// Codable DTO mediating between Kizba's domain ``PassSecret`` /
/// ``PassEntry`` pair and external password-manager export formats
/// (Bitwarden JSON, generic CSV, 1Password CSV).
///
/// Surface is intentionally narrow: only fields universally supported
/// across 1Password / Bitwarden / KeePassXC exports. Anything more
/// exotic goes into ``extraFields`` so the bridge layer can round-trip
/// custom metadata when both importer and exporter understand it.
public struct ExportRecord: Codable, Sendable, Equatable {

    /// Full pass-style path, e.g. `"work/aws/root"`. Forward slashes
    /// denote folders. Sanitised by the importer (no `:` or `\`).
    public let path: String

    /// Cleartext password. Required — records with no password are
    /// filtered out at parse time and reported as parse warnings.
    public let password: String

    public let username: String?
    public let url: String?
    public let notes: String?

    /// `otpauth://` URI if present. Round-trips through Bitwarden's
    /// `login.totp` field and the generic CSV `totp` column.
    public let totp: String?

    /// Arbitrary additional fields that did not map onto one of the
    /// standard slots above. Exporters that don't understand the keys
    /// drop them silently.
    public let extraFields: [String: String]

    public init(
        path: String,
        password: String,
        username: String? = nil,
        url: String? = nil,
        notes: String? = nil,
        totp: String? = nil,
        extraFields: [String: String] = [:]
    ) {
        self.path = path
        self.password = password
        self.username = username
        self.url = url
        self.notes = notes
        self.totp = totp
        self.extraFields = extraFields
    }
}
