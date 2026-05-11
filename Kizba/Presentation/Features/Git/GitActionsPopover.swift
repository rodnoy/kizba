import SwiftUI

struct GitActionsPopover: View {

    let model: GitStatusModel

    private let onPull: () async -> Void
    private let onPush: () async -> Void
    private let onRefresh: () async -> Void
    private let onCancel: () -> Void
    private let onOpenTerminal: () -> Void

    @Environment(\.theme) private var theme

    init(
        model: GitStatusModel,
        onPull: (() async -> Void)? = nil,
        onPush: (() async -> Void)? = nil,
        onRefresh: (() async -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onOpenTerminal: (() -> Void)? = nil
    ) {
        self.model = model
        self.onPull = onPull ?? {}
        self.onPush = onPush ?? {}
        self.onRefresh = onRefresh ?? { await model.loadStatus() }
        self.onCancel = onCancel ?? { model.cancelCurrentLoad() }
        self.onOpenTerminal = onOpenTerminal ?? {}
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Git Actions")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.onSurface)

            Text("Manage repository status and sync actions.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)

            Button("Refresh") {
                Task { await onRefresh() }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(!model.canRefresh)
            .accessibilityHint("Refreshes the current git repository status")

            Button("Pull") {
                Task { await onPull() }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(!model.canPull)
            .accessibilityHint("Pulls latest changes from the remote")

            Button("Push") {
                Task { await onPush() }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(!model.canPush)
            .accessibilityHint("Pushes local commits to the remote")

            Divider()

            Button("Open Terminal") {
                onOpenTerminal()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .accessibilityHint("Opens Terminal at the password store location")

            if GitActionsPopover.showsInFlightUI(for: model.operationState) {
                HStack(spacing: theme.spacing.sm) {
                    ProgressView()

                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Cancels the current git operation")
                }
            }
        }
        .frame(minWidth: 240)
        .padding(theme.spacing.md)
    }

    static func showsInFlightUI(for state: GitStatusModel.OperationState) -> Bool {
        state != .idle
    }
}
