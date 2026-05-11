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
    public let hasRemote: Bool
    public let lastFetchAt: Date?

    public init(
        isGitRepository: Bool = false,
        branch: String? = nil,
        hasLocalChanges: Bool = false,
        hasConflicts: Bool = false,
        aheadCount: Int = 0,
        behindCount: Int = 0,
        hasRemote: Bool = false,
        lastFetchAt: Date? = nil
    ) {
        self.isGitRepository = isGitRepository
        self.branch = branch
        self.hasLocalChanges = hasLocalChanges
        self.hasConflicts = hasConflicts
        self.aheadCount = aheadCount
        self.behindCount = behindCount
        self.hasRemote = hasRemote
        self.lastFetchAt = lastFetchAt
    }

    public static let notARepository = GitStatus()
}
