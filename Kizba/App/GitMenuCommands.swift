import SwiftUI

struct GitMenuCommands: Commands {

    let state: AppState
    let onOpenTerminal: (() -> Void)?

    init(
        state: AppState,
        onOpenTerminal: (() -> Void)? = nil
    ) {
        self.state = state
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
                    Task {
                        await state.gitStatusModel?.pull()
                    }
                }
                .disabled(!Self.canPull(state: state))

                Button("Push") {
                    Task {
                        await state.gitStatusModel?.push()
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
