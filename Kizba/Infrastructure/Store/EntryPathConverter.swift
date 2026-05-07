//
//  EntryPathConverter.swift
//  Kizba
//
//  Pure URL → entry path string conversion for the password store.
//
//  Strictly IO-free: no FileManager, no shell, no logging. The
//  converter never inspects file contents or existence — its only
//  inputs are the two URLs supplied by the caller. It must never
//  log paths or filenames either, since entry names can themselves
//  be sensitive.
//

import Foundation

/// Converts a file `URL` inside the password store into the canonical
/// "entry path" string used by `pass` (relative to the store root,
/// without the trailing `.gpg` extension).
public nonisolated struct EntryPathConverter: Sendable {

    /// Returns the entry path string (relative to the store root,
    /// without the `.gpg` extension) for a given file URL inside the
    /// password store, or `nil` if the file is not an entry (for
    /// example, not a `.gpg` file or outside the store root).
    ///
    /// The function is pure and deterministic: it does **not** touch
    /// the filesystem and does not check for file existence. Unicode
    /// and whitespace in path components are preserved verbatim; only
    /// the final `.gpg` extension is stripped.
    ///
    /// - Parameters:
    ///   - fileURL: an absolute file URL pointing at a candidate entry.
    ///   - storeRoot: the absolute file URL of the password store root.
    /// - Returns: the entry path with `/` separators, or `nil` if the
    ///   URL is not a `.gpg` descendant of the store root.
    public static func entryPath(from fileURL: URL, storeRoot: URL) -> String? {
        // Only `.gpg` files are entries (case-insensitive on the
        // extension itself; component preservation is unaffected).
        guard fileURL.pathExtension.lowercased() == "gpg" else {
            return nil
        }

        // Compare standardized path components so trailing slashes
        // and `.` segments do not produce false negatives.
        let fileComponents = fileURL.standardizedFileURL.pathComponents
        let rootComponents = storeRoot.standardizedFileURL.pathComponents

        // The file URL must be a strict descendant of the store root.
        guard fileComponents.count > rootComponents.count else {
            return nil
        }
        for (i, component) in rootComponents.enumerated()
        where component != fileComponents[i] {
            return nil
        }

        // Components relative to the store root.
        var relative = Array(fileComponents[rootComponents.count...])
        guard let last = relative.last else { return nil }

        // Strip only the final `.gpg` extension from the filename;
        // preserve any earlier dots in the basename.
        let stripped: String
        if let dot = last.range(of: ".", options: .backwards),
           last[dot.upperBound...].lowercased() == "gpg" {
            stripped = String(last[..<dot.lowerBound])
        } else {
            // Should not happen given the pathExtension check above,
            // but stay defensive rather than force-unwrap.
            return nil
        }
        relative[relative.count - 1] = stripped

        // An empty filename (e.g. `.gpg`) is not a valid entry.
        guard !stripped.isEmpty else { return nil }

        return relative.joined(separator: "/")
    }
}
