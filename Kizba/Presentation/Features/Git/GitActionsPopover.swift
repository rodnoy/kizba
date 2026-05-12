import SwiftUI

struct GitActionsPopover: View {

    let model: GitStatusModel

    private let onPull: () async -> Void
    private let onPush: () async -> Void
    private let onRefresh: () async -> Void
    private let onCancel: () -> Void
    private let onOpenTerminal: () -> Void

    @Environment(\.theme) private var theme

    // MVP4 fix-pack v1, Fix 2 — every closure is REQUIRED. Previously
    // they defaulted to `{}` / `{ await model.loadStatus() }`, which
    // made it possible (and common) for a callsite to forget to pass
    // an action and silently end up with a no-op button. Forcing the
    // parameters makes regressions a compile error instead of a
    // dead-button.
    init(
        model: GitStatusModel,
        onPull: @escaping () async -> Void,
        onPush: @escaping () async -> Void,
        onRefresh: @escaping () async -> Void,
        onCancel: @escaping () -> Void,
        onOpenTerminal: @escaping () -> Void
    ) {
        self.model = model
        self.onPull = onPull
        self.onPush = onPush
        self.onRefresh = onRefresh
        self.onCancel = onCancel
        self.onOpenTerminal = onOpenTerminal
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
            .accessibilityLabel("Refresh")
            .accessibilityHint("Refreshes the current git repository status")

            Button("Pull") {
                Task { await onPull() }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(!model.canPull)
            .accessibilityLabel("Pull")
            .accessibilityHint("Pulls latest changes from the remote")

            Button("Push") {
                Task { await onPush() }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(!model.canPush)
            .accessibilityLabel("Push")
            .accessibilityHint("Pushes local commits to the remote")

            Divider()

            Button("Open Terminal") {
                onOpenTerminal()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Open Terminal")
            .accessibilityHint("Opens Terminal at the password store location")

            if GitActionsPopover.showsInFlightUI(for: model.operationState) {
                HStack(spacing: theme.spacing.sm) {
                    ProgressView()
                        .accessibilityLabel("Git operation in progress")
                        .accessibilityValue(Self.progressAccessibilityValue(for: model.operationState))

                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Cancel git operation")
                    .accessibilityHint("Cancels the current git operation")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .frame(minWidth: 240)
        .padding(theme.spacing.md)
        .accessibilityElement(children: .contain)
    }

    static func showsInFlightUI(for state: GitStatusModel.OperationState) -> Bool {
        state != .idle
    }

    static func progressAccessibilityValue(for state: GitStatusModel.OperationState) -> String {
        switch state {
        case .pulling:
            return "Pulling"
        case .pushing, .idle:
            return "Pushing"
        }
    }
}
