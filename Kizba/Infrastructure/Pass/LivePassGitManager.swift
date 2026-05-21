import Foundation

public actor LivePassGitManager: PassGitManaging {

    private let passCLI: PassCLI
    private let gitExecutable: URL
    private let storeLocationProvider: @Sendable () async -> URL

    public init(
        passCLI: PassCLI,
        gitExecutable: URL,
        storeLocationProvider: @escaping @Sendable () async -> URL
    ) {
        self.passCLI = passCLI
        self.gitExecutable = gitExecutable
        self.storeLocationProvider = storeLocationProvider
    }

    public func gitStatus() async throws -> GitStatus {
        let storeURL = await storeLocationProvider()
        let storePath = storeURL.path

        do {
            return try await passCLI.gitStatus(storePath: storePath, gitExecutable: gitExecutable)
        } catch let error as PassError {
            if error == .gitNotInitialized {
                return await MainActor.run { GitStatus.notARepository }
            }
            throw error
        } catch {
            throw error
        }
    }

    public func gitPull(timeoutSeconds: Int) async throws {
        let storeURL = await storeLocationProvider()
        let storePath = storeURL.path

        do {
            try await passCLI.gitPull(storePath: storePath, timeoutSeconds: timeoutSeconds)
        } catch let error as CancellationError {
            throw error
        } catch let error as PassError {
            throw error
        } catch {
            throw error
        }
    }

    public func gitFetch(timeoutSeconds: Int) async throws {
        let storeURL = await storeLocationProvider()
        let storePath = storeURL.path

        do {
            try await passCLI.gitFetch(storePath: storePath, timeoutSeconds: timeoutSeconds)
        } catch let error as CancellationError {
            throw error
        } catch let error as PassError {
            throw error
        } catch {
            throw error
        }
    }

    public func gitPush(timeoutSeconds: Int) async throws -> GitPushOutcome {
        let storeURL = await storeLocationProvider()
        let storePath = storeURL.path

        do {
            return try await passCLI.gitPush(storePath: storePath, timeoutSeconds: timeoutSeconds)
        } catch let error as CancellationError {
            throw error
        } catch let error as PassError {
            throw error
        } catch {
            throw error
        }
    }
}
