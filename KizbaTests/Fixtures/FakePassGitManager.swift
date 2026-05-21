import Foundation
@testable import Kizba

actor FakePassGitManager: PassGitManaging {

    var nextStatus: Result<GitStatus, Error> = .success(.notARepository)
    var fetchResults: [Result<Void, Error>] = []
    var pullResults: [Result<Void, Error>] = []
    var pushResults: [Result<GitPushOutcome, Error>] = []

    private(set) var statusCallCount: Int = 0
    private(set) var fetchCallCount: Int = 0
    private(set) var pullCallCount: Int = 0
    private(set) var pushCallCount: Int = 0

    var artificialDelay: Duration? = nil

    func setArtificialDelay(_ delay: Duration?) {
        artificialDelay = delay
    }

    func setNextStatus(_ result: Result<GitStatus, Error>) {
        nextStatus = result
    }

    func setPullResults(_ results: [Result<Void, Error>]) {
        pullResults = results
    }

    func setFetchResults(_ results: [Result<Void, Error>]) {
        fetchResults = results
    }

    func setPushResults(_ results: [Result<GitPushOutcome, Error>]) {
        pushResults = results
    }

    func gitStatus() async throws -> GitStatus {
        statusCallCount += 1
        if let artificialDelay {
            try await Task.sleep(for: artificialDelay)
        }

        switch nextStatus {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        }
    }

    func gitPull(timeoutSeconds _: Int) async throws {
        pullCallCount += 1
        if let artificialDelay {
            try await Task.sleep(for: artificialDelay)
        }

        if !pullResults.isEmpty {
            switch pullResults.removeFirst() {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    func gitFetch(timeoutSeconds _: Int) async throws {
        fetchCallCount += 1
        if let artificialDelay {
            try await Task.sleep(for: artificialDelay)
        }

        if !fetchResults.isEmpty {
            switch fetchResults.removeFirst() {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    func gitPush(timeoutSeconds _: Int) async throws -> GitPushOutcome {
        pushCallCount += 1
        if let artificialDelay {
            try await Task.sleep(for: artificialDelay)
        }

        if !pushResults.isEmpty {
            switch pushResults.removeFirst() {
            case .success(let outcome):
                return outcome
            case .failure(let error):
                throw error
            }
        }

        return .pushed
    }
}
