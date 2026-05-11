//
//  GitStatusParser.swift
//  Kizba
//

import Foundation

public enum GitStatusParser: Sendable {

    public static func parse(_ stdout: String) -> GitStatus {
        var branch: String?
        var hasRemote = false
        var aheadCount = 0
        var behindCount = 0
        var hasLocalChanges = false
        var hasConflicts = false

        for rawLine in stdout.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("# ") {
                parseHeader(
                    line,
                    branch: &branch,
                    hasRemote: &hasRemote,
                    aheadCount: &aheadCount,
                    behindCount: &behindCount
                )
                continue
            }

            if line.hasPrefix("u ") {
                hasConflicts = true
                hasLocalChanges = true
                continue
            }

            if line.hasPrefix("1 ") || line.hasPrefix("2 ") || line.hasPrefix("? ") {
                hasLocalChanges = true
            }
        }

        return GitStatus(
            isGitRepository: true,
            branch: branch,
            hasLocalChanges: hasLocalChanges,
            hasConflicts: hasConflicts,
            aheadCount: aheadCount,
            behindCount: behindCount,
            hasRemote: hasRemote,
            lastFetchAt: nil
        )
    }

    private static func parseHeader(
        _ line: String,
        branch: inout String?,
        hasRemote: inout Bool,
        aheadCount: inout Int,
        behindCount: inout Int
    ) {
        let payload = String(line.dropFirst(2))

        if payload.hasPrefix("branch.head ") {
            let value = String(payload.dropFirst("branch.head ".count))
            if value == "(detached)" {
                branch = nil
            } else if !value.isEmpty {
                branch = value
            }
            return
        }

        if payload.hasPrefix("branch.upstream ") {
            let value = String(payload.dropFirst("branch.upstream ".count))
            if !value.isEmpty {
                hasRemote = true
            }
            return
        }

        if payload.hasPrefix("branch.ab ") {
            let values = payload
                .dropFirst("branch.ab ".count)
                .split(whereSeparator: { $0.isWhitespace })

            for value in values {
                if value.hasPrefix("+"), let parsed = Int(value.dropFirst()) {
                    aheadCount = parsed
                    continue
                }
                if value.hasPrefix("-"), let parsed = Int(value.dropFirst()) {
                    behindCount = parsed
                }
            }
        }
    }
}
