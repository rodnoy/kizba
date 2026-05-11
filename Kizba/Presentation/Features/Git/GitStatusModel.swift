import Foundation
import Observation

@Observable
@MainActor
public final class GitStatusModel {

    public enum LoadState: Sendable, Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    public enum OperationState: Sendable, Equatable {
        case idle
        case pulling
        case pushing
    }

    public var status: GitStatus = .notARepository
    public var loadState: LoadState = .idle
    public var operationState: OperationState = .idle
    public var lastError: PassError?

    private var generation: UInt64 = 0
    private var currentTask: Task<Void, Never>?
    private var changeSubscriptionTask: Task<Void, Never>?

    private let gitManager: any PassGitManaging
    private let passManager: any PassManaging
    private let appState: AppState
    private let router: AppRouter
    private let toastCenter: ToastCenter
    private let settingsStore: any SettingsStoring

    public var badgeText: String {
        guard status.isGitRepository else { return "—" }
        if status.hasConflicts { return "⚠" }
        if status.aheadCount > 0, status.behindCount > 0 {
            return "↑\(status.aheadCount) ↓\(status.behindCount)"
        }
        if status.aheadCount > 0 { return "↑\(status.aheadCount)" }
        if status.behindCount > 0 { return "↓\(status.behindCount)" }
        if status.hasLocalChanges { return "●" }
        return "✓"
    }

    var badgeAccessibilityLabel: String {
        guard status.isGitRepository else { return "Git: unavailable" }
        if status.hasConflicts { return "Git: merge conflict" }
        if status.aheadCount > 0, status.behindCount > 0 {
            return "Git: \(status.aheadCount) ahead, \(status.behindCount) behind"
        }
        if status.aheadCount > 0 { return "Git: \(status.aheadCount) ahead" }
        if status.behindCount > 0 { return "Git: \(status.behindCount) behind" }
        if status.hasLocalChanges { return "Git: local changes" }
        return "Git: clean"
    }

    var canPull: Bool {
        status.isGitRepository
            && status.hasRemote
            && operationState == .idle
            && !appState.anyWriteInFlight
    }

    var canPush: Bool {
        status.isGitRepository
            && status.hasRemote
            && status.aheadCount > 0
            && operationState == .idle
            && !appState.anyWriteInFlight
    }

    var canRefresh: Bool {
        loadState != .loading && operationState == .idle
    }

    var isFullyClean: Bool {
        status.isGitRepository && !status.hasLocalChanges && !status.hasConflicts
    }

    init(
        gitManager: any PassGitManaging,
        passManager: any PassManaging,
        appState: AppState,
        router: AppRouter,
        toastCenter: ToastCenter,
        settingsStore: any SettingsStoring = InternalNoopSettingsStore()
    ) {
        self.gitManager = gitManager
        self.passManager = passManager
        self.appState = appState
        self.router = router
        self.toastCenter = toastCenter
        self.settingsStore = settingsStore
    }

    public func observeChanges() async {
        guard changeSubscriptionTask == nil else { return }

        let stream = passManager.changes
        let task = Task { [weak self] in
            for await _ in stream {
                if Task.isCancelled { return }
                guard let self else { return }
                await self.loadStatus()
            }
        }
        changeSubscriptionTask = task

        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }

        changeSubscriptionTask = nil
    }

    public func stop() {
        changeSubscriptionTask?.cancel()
        changeSubscriptionTask = nil
    }

    public func loadStatus() async {
        generation &+= 1
        let token = generation
        loadState = .loading

        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await self.gitManager.gitStatus()
                try Task.checkCancellation()
                guard token == self.generation else { return }
                self.status = result
                self.loadState = .loaded
                self.lastError = nil
                self.refreshConflictAutoDismiss()
            } catch is CancellationError {
                guard token == self.generation else { return }
                self.loadState = .idle
            } catch {
                guard token == self.generation else { return }
                let mappedError = (error as? PassError)
                    ?? PassError.shellFailure(exitCode: -1, stderrExcerpt: "")
                self.lastError = mappedError
                self.loadState = .failed

                let presentation = ErrorPresentation.present(for: mappedError)
                switch presentation {
                case .silent:
                    break
                case .toastWithDiagnostics(let message),
                     .inlineWithDiagnostics(let message):
                    self.toastCenter.post(
                        Toast(severity: .danger, title: "Git status failed", message: message)
                    )
                case .onboarding(let message):
                    self.toastCenter.post(
                        Toast(severity: .warning, title: "Git setup required", message: message)
                    )
                case .banner(let message, _):
                    self.toastCenter.post(
                        Toast(severity: .danger, title: "Git status failed", message: message)
                    )
                case .emptyState(let nudge):
                    self.toastCenter.post(
                        Toast(severity: .warning, title: nudge.title, message: nudge.actionTitle)
                    )
                }
            }

            if token == self.generation {
                self.currentTask = nil
            }
        }

        await currentTask?.value
    }

    public func cancelCurrentLoad() {
        generation &+= 1
        currentTask?.cancel()
        currentTask = nil
        if loadState == .loading {
            loadState = .idle
        }
    }

    private func refreshConflictAutoDismiss() {
        if router.isGitConflictBannerPresented, !status.hasConflicts {
            router.dismissGitConflictBanner()
        }
    }
}

struct InternalNoopSettingsStore: SettingsStoring {
    nonisolated func value<Value: SettingsValue>(for key: SettingsKey<Value>) -> Value? { nil }
    nonisolated func set<Value: SettingsValue>(_ value: Value?, for key: SettingsKey<Value>) {}
    nonisolated func removeValue(forKey key: String) {}
    nonisolated func resetAll() {}
    nonisolated func registerDefaults(_ defaults: [String : Any]) {}
}
