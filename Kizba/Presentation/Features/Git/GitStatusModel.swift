import Foundation
import Observation

@Observable
@MainActor
public final class GitStatusModel {

    private nonisolated static let gitOperationTimeoutSecondsKey = SettingsKey<Int>(SettingsKeys.gitOperationTimeoutSeconds)

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

    /// MVP4 fix-pack v1, Fix 6 — task handle for the in-flight
    /// pull/push so ``cancelOperation()`` can `Task.cancel()` it. The
    /// cancellation propagates through `await
    /// gitManager.gitPull/gitPush` → `ProcessShellRunner` SIGTERM
    /// (see MVP2 E.2). Cleared on completion (success/failure/cancel).
    private var operationTask: Task<Void, Never>?

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
                // MVP4 fix-pack v1, Fix 1 — auto-refresh path. Do NOT
                // mutate `loadState`; otherwise the badge flickers
                // and the Refresh button gates `canRefresh` against
                // an in-flight reload it never asked for.
                await self.refreshStatusQuietly()
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

    /// MVP4 fix-pack v1, Fix 1 — auto-refresh seam used by FSEvents
    /// subscribers and `scenePhase`-driven re-fetches. Updates
    /// ``status`` / ``lastError`` on completion but does NOT touch
    /// ``loadState``, so the user-visible "Refresh" affordance stays
    /// clickable and the badge does not flicker into a "loading"
    /// state for background work the user did not initiate.
    func refreshStatusQuietly() async {
        do {
            let result = try await gitManager.gitStatus()
            try Task.checkCancellation()
            self.status = result
            self.lastError = nil
            self.refreshConflictAutoDismiss()
        } catch is CancellationError {
            // Quiet; no state change.
        } catch {
            // Quiet failure path: capture the mapped error so
            // diagnostics can pick it up, but do NOT post a toast or
            // flip into `.failed`. Manual `loadStatus()` remains the
            // user-visible failure surface.
            let mapped = (error as? PassError)
                ?? PassError.shellFailure(exitCode: -1, stderrExcerpt: "")
            self.lastError = mapped
        }
    }

    public func stop() {
        changeSubscriptionTask?.cancel()
        changeSubscriptionTask = nil
    }

    func dismissGitConflictBanner() {
        router.dismissGitConflictBanner()
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

    public func pull() async {
        guard canPull else { return }

        // MVP4 fix-pack v1, Fix 6 — wrap the operation in a Task so
        // ``cancelOperation()`` can interrupt it via `Task.cancel()`.
        // The Task body owns the lockout/state mutations so a
        // mid-flight cancellation still releases `activeWriteOps`
        // and resets `operationState`.
        operationTask?.cancel()
        let token = nextOperationToken()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runPull()
        }
        operationTask = task
        await task.value
        // Clear only if a newer operation has not replaced this one.
        if operationToken == token {
            operationTask = nil
        }
    }

    private func runPull() async {
        var operationError: PassError?
        var wasCancelled = false
        operationState = .pulling
        appState.beginWrite(.gitPull)
        defer {
            operationState = .idle
            appState.endWrite(.gitPull)
        }

        do {
            try await gitManager.gitPull(timeoutSeconds: gitOperationTimeoutSeconds)
            toastCenter.post(
                Toast(severity: .success, title: "Pull complete", message: nil)
            )
        } catch is CancellationError {
            // Silently cancelled — skip the post-op `loadStatus()`
            // below so cancellation actually finishes promptly
            // instead of running a fresh gitStatus call right after.
            wasCancelled = true
        } catch let error as PassError where error == .cancelled {
            // Same: when the inner shell runner translates a
            // Task.cancel() into `PassError.cancelled`, treat it as
            // a cancellation and skip the post-op refresh.
            wasCancelled = true
        } catch {
            let mappedError = (error as? PassError)
                ?? PassError.shellFailure(exitCode: -1, stderrExcerpt: "")
            operationError = mappedError
            lastError = mappedError
            if case .gitConflict = mappedError {
                router.presentGitConflictBanner()
            } else {
                toastCenter.post(
                    Toast(
                        severity: .danger,
                        title: "Pull failed",
                        message: userMessage(for: mappedError)
                    )
                )
            }
        }

        if !wasCancelled {
            await loadStatus()
        }
        if let operationError {
            lastError = operationError
        }
    }

    public func push() async {
        guard canPush else { return }

        // MVP4 fix-pack v1, Fix 6 — see `pull()`.
        operationTask?.cancel()
        let token = nextOperationToken()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.runPush()
        }
        operationTask = task
        await task.value
        if operationToken == token {
            operationTask = nil
        }
    }

    private var operationToken: UInt64 = 0

    private func nextOperationToken() -> UInt64 {
        operationToken &+= 1
        return operationToken
    }

    private func runPush() async {
        var operationError: PassError?
        var wasCancelled = false
        operationState = .pushing
        appState.beginWrite(.gitPush)
        defer {
            operationState = .idle
            appState.endWrite(.gitPush)
        }

        do {
            let outcome = try await gitManager.gitPush(timeoutSeconds: gitOperationTimeoutSeconds)
            switch outcome {
            case .pushed:
                toastCenter.post(
                    Toast(severity: .success, title: "Push complete", message: nil)
                )
            case .alreadyUpToDate:
                toastCenter.post(
                    Toast(severity: .info, title: "Already up to date", message: nil)
                )
            }
        } catch is CancellationError {
            wasCancelled = true
        } catch let error as PassError where error == .cancelled {
            wasCancelled = true
        } catch {
            let mappedError = (error as? PassError)
                ?? PassError.shellFailure(exitCode: -1, stderrExcerpt: "")
            operationError = mappedError
            lastError = mappedError
            toastCenter.post(
                Toast(
                    severity: .danger,
                    title: "Push failed",
                    message: userMessage(for: mappedError)
                )
            )
        }

        if !wasCancelled {
            await loadStatus()
        }
        if let operationError {
            lastError = operationError
        }
    }

    /// MVP4 fix-pack v1, Fix 6 — cancels an in-flight pull/push. The
    /// cancellation propagates via `Task.cancel()` →
    /// `await gitManager.gitPull/gitPush` → `ProcessShellRunner`
    /// SIGTERM (existing pattern from MVP2 E.2). Idempotent: a no-op
    /// when no operation is in flight.
    public func cancelOperation() {
        operationTask?.cancel()
    }

    /// MVP4 fix-pack v1, Fix 4 — opens Terminal.app at the active
    /// password-store directory. Single source of truth; the popover,
    /// the `Git` menu, and the conflict-banner sheet all delegate
    /// here. `NSWorkspace.open(URL)` opens a directory in Finder, NOT
    /// Terminal — `open -a Terminal <path>` is the correct invocation.
    public func openTerminalAtStore() {
        let storeURL = passManager.storeLocation()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", storeURL.path]
        // Errors are intentionally swallowed: the user-visible signal
        // is whether Terminal launches. Logging via `Log.git` could
        // be added later if a recurring failure surface needs
        // diagnosis.
        try? process.run()
    }

    private var gitOperationTimeoutSeconds: Int {
        let configured = settingsStore.value(for: Self.gitOperationTimeoutSecondsKey)
        let bounds = SettingsKeys.gitOperationTimeoutBounds
        guard let configured else { return SettingsKeys.defaultGitOperationTimeoutSeconds }
        return min(max(configured, bounds.lowerBound), bounds.upperBound)
    }

    private func userMessage(for error: PassError) -> String? {
        let presentation = ErrorPresentation.present(for: error)
        switch presentation {
        case .silent:
            return nil
        case .toastWithDiagnostics(let message),
             .inlineWithDiagnostics(let message):
            return message
        case .onboarding(let message):
            return message
        case .banner(let message, _):
            return message
        case .emptyState(let nudge):
            return nudge.actionTitle
        }
    }

    private func refreshConflictAutoDismiss() {
        if status.hasConflicts, !router.isGitConflictBannerPresented {
            router.presentGitConflictBanner()
        } else if router.isGitConflictBannerPresented, !status.hasConflicts {
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
