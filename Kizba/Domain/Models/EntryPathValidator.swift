//
//  EntryPathValidator.swift
//  Kizba
//
//  Pure validator for user-entered `pass` entry paths (e.g.
//  `personal/github`). The user enters a logical path relative to
//  the store root; `pass` itself appends `.gpg` and resolves the
//  filesystem location. We reject anything that would either confuse
//  `pass` or escape the store.
//

import Foundation

/// Validates entry paths typed into the new/edit/move sheets.
///
/// Strict, no implicit trimming: the user sees the exact characters
/// they typed and the validator either accepts or rejects.
public enum EntryPathValidator {

    /// Reasons a path may be rejected. Each case carries enough
    /// information for the form to render a specific inline error.
    public enum ValidationError: Error, Equatable, Sendable {
        case empty
        case leadingSlash
        case trailingSlash
        case dotComponent
        case dotDotComponent
        case gpgSuffix
        case whitespaceComponent
    }

    /// Returns the original path on success, or a specific
    /// `ValidationError` describing the first rule violated. Order of
    /// checks favours the most user-visible failures first (empty,
    /// slash placement, suffix), then per-component analysis.
    public static func validate(_ path: String) -> Result<String, ValidationError> {
        if path.isEmpty {
            return .failure(.empty)
        }
        if path.hasPrefix("/") {
            return .failure(.leadingSlash)
        }
        if path.hasSuffix("/") {
            return .failure(.trailingSlash)
        }
        if path.hasSuffix(".gpg") {
            return .failure(.gpgSuffix)
        }
        // Reject leading or trailing whitespace at the path level —
        // a leading-space component would otherwise be reported as
        // "empty" only if it were entirely empty.
        if let first = path.first, first.isWhitespace {
            return .failure(.whitespaceComponent)
        }
        if let last = path.last, last.isWhitespace {
            return .failure(.whitespaceComponent)
        }

        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        for component in components {
            if component == ".." {
                return .failure(.dotDotComponent)
            }
            if component == "." {
                return .failure(.dotComponent)
            }
            // Empty component (consecutive `//`) or a component made
            // entirely of whitespace.
            if component.isEmpty || component.allSatisfy({ $0.isWhitespace }) {
                return .failure(.whitespaceComponent)
            }
        }

        return .success(path)
    }
}
