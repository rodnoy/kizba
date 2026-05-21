//
//  PassGitErrorMapper.swift
//  Kizba
//

import Foundation

public enum PassGitErrorMapper: Sendable {

    public enum GitOperation: Sendable, Equatable {
        case status
        case fetch
        case pull
        case push
    }

    public static func map(
        stderr: String,
        exitCode: Int32,
        operation: GitOperation
    ) -> (error: PassError, excerpt: String) {
        let _ = exitCode
        let _ = operation

        let excerpt = PassErrorMapper.sanitize(stderr)
        let lower = stderr.lowercased()

        if lower.contains("not a git repository") {
            return (.gitNotInitialized, excerpt)
        }

        if containsAny(lower, needles: [
            "no configured push destination",
            "does not appear to be a git repository",
        ]) {
            return (.gitNoRemote, excerpt)
        }

        if containsAny(lower, needles: [
            "authentication failed",
            "permission denied (publickey",
            "could not read username",
        ]) {
            return (.gitAuthFailed, excerpt)
        }

        if containsAny(lower, needles: [
            "conflict",
            "merge conflict",
            "automatic merge failed",
        ]) {
            let conflictPaths = extractConflictPaths(from: stderr)
            return (.gitConflict(paths: conflictPaths), excerpt)
        }

        if containsAny(lower, needles: [
            "could not resolve host",
            "network is unreachable",
            "operation timed out",
        ]) {
            return (.gitNetworkUnavailable, excerpt)
        }

        if let rejectionLine = firstMatchingLine(
            in: stderr,
            needles: ["updates were rejected", "non-fast-forward", "fetch first"]
        ) {
            return (.gitRejected(reason: PassErrorMapper.sanitize(rejectionLine)), excerpt)
        }

        return (.writeFailed(reason: excerpt), excerpt)
    }

    private static func containsAny(_ haystack: String, needles: [String]) -> Bool {
        for needle in needles where haystack.contains(needle) {
            return true
        }
        return false
    }

    private static func extractConflictPaths(from stderr: String) -> [String]? {
        var paths: [String] = []

        for rawLine in stderr.components(separatedBy: .newlines) {
            guard rawLine.range(of: "CONFLICT", options: .caseInsensitive) != nil,
                  let markerRange = rawLine.range(of: "Merge conflict in ", options: .caseInsensitive)
            else {
                continue
            }

            let path = String(rawLine[markerRange.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !path.isEmpty {
                paths.append(path)
                if paths.count == 20 {
                    break
                }
            }
        }

        return paths.isEmpty ? nil : paths
    }

    private static func firstMatchingLine(in stderr: String, needles: [String]) -> String? {
        for rawLine in stderr.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let lowerLine = line.lowercased()
            for needle in needles where lowerLine.contains(needle) {
                return line
            }
        }

        return nil
    }
}
