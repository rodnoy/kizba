// GitPushOutcome and PassGitManaging
import Foundation

public enum GitPushOutcome: Sendable, Equatable {
    case pushed
    case alreadyUpToDate
}

public protocol PassGitManaging: Sendable {
    func gitStatus() async throws -> GitStatus
    func gitFetch(timeoutSeconds: Int) async throws
    func gitPull(timeoutSeconds: Int) async throws -> Void
    func gitPush(timeoutSeconds: Int) async throws -> GitPushOutcome
}
