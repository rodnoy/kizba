//
//  GitStatus.swift
//  Kizba
//
//  Value type representing the git status of the password store.
//

import Foundation

public struct GitStatus: Sendable, Hashable, Equatable {

    public let isGitRepository: Bool
    public let branch: String?
    public let hasLocalChanges: Bool
    public let hasConflicts: Bool
    public let aheadCount: Int
    public let behindCount: Int

    /// `true` when the current branch has an upstream tracking ref
    /// (e.g. `origin/main`). Detected from `git status
    /// --porcelain=v2 --branch`'s `# branch.upstream` line.
    ///
    /// MVP4 fix-pack v1, Fix 5 — was previously named `hasRemote`,
    /// but its meaning is "has upstream tracking", not "has any
    /// remote configured". Pull/Push UI gates should consult
    /// ``hasRemote`` instead.
    public let hasUpstream: Bool

    /// `true` when the store has at least one configured git remote
    /// (detected via `git -C <store> remote`). A repo with a remote
    /// but no upstream tracking still allows `git pull` / `git push`
    /// when the user supplies the remote name explicitly. Drives the
    /// Pull / Push UI affordances.
    public let hasRemote: Bool

    public let lastFetchAt: Date?

    public init(
        isGitRepository: Bool = false,
        branch: String? = nil,
        hasLocalChanges: Bool = false,
        hasConflicts: Bool = false,
        aheadCount: Int = 0,
        behindCount: Int = 0,
        hasUpstream: Bool = false,
        hasRemote: Bool = false,
        lastFetchAt: Date? = nil
    ) {
        self.isGitRepository = isGitRepository
        self.branch = branch
        self.hasLocalChanges = hasLocalChanges
        self.hasConflicts = hasConflicts
        self.aheadCount = aheadCount
        self.behindCount = behindCount
        self.hasUpstream = hasUpstream
        self.hasRemote = hasRemote
        self.lastFetchAt = lastFetchAt
    }

    public static let notARepository = GitStatus()
}
