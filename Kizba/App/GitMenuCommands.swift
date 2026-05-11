import SwiftUI

struct GitMenuCommands: Commands {

    let state: AppState
    let onPull: (() async -> Void)?
    let onPush: (() async -> Void)?
    let onOpenTerminal: (() -> Void)?

    init(
        state: AppState,
        onPull: (() async -> Void)? = nil,
        onPush: (() async -> Void)? = nil,
        onOpenTerminal: (() -> Void)? = nil
    ) {
        self.state = state
        self.onPull = onPull
        self.onPush = onPush
        self.onOpenTerminal = onOpenTerminal
    }

    var body: some Commands {
        if Self.isVisible(state: state) {
            CommandMenu("Git") {
                Button("Refresh Status") {
                    Task {
                        await state.gitStatusModel?.loadStatus()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!Self.canRefresh(state: state))

                Button("Pull") {
                    guard let onPull else { return }
                    Task {
                        await onPull()
                    }
                }
                .disabled(!Self.canPull(state: state))

                Button("Push") {
                    guard let onPush else { return }
                    Task {
                        await onPush()
                    }
                }
                .disabled(!Self.canPush(state: state))

                Button("Open Terminal at Store") {
                    onOpenTerminal?()
                }
                .disabled(state.gitStatusModel == nil)
            }
        }
    }

    static func isVisible(state: AppState) -> Bool {
        state.gitStatusModel != nil
    }

    static func canRefresh(state: AppState) -> Bool {
        guard let model = state.gitStatusModel else { return false }
        return model.loadState != .loading && model.operationState == .idle
    }

    static func canPull(state: AppState) -> Bool {
        guard let model = state.gitStatusModel else { return false }
        return model.status.isGitRepository
            && model.status.hasRemote
            && model.operationState == .idle
            && !state.anyWriteInFlight
    }

    static func canPush(state: AppState) -> Bool {
        guard let model = state.gitStatusModel else { return false }
        return model.status.isGitRepository
            && model.status.hasRemote
            && model.status.aheadCount > 0
            && model.operationState == .idle
            && !state.anyWriteInFlight
    }
}
