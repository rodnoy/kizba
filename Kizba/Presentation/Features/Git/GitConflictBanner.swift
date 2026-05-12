import SwiftUI

struct GitConflictBanner: View {

    let model: GitStatusModel
    let storePath: String

    private let openTerminalAction: () -> Void

    @Environment(\.theme) private var theme

    init(
        model: GitStatusModel,
        storePath: String,
        openTerminalAction: (() -> Void)? = nil
    ) {
        self.model = model
        self.storePath = storePath
        self.openTerminalAction = openTerminalAction ?? {}
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Merge conflicts detected")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.onSurface)

            Text("Some entries have conflicting changes. Kizba does not resolve them automatically.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurfaceMuted)

            Text("Merge conflict in")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)

            Text(storePath)
                .font(theme.typography.mono)
                .foregroundStyle(theme.colors.onSurface)
                .textSelection(.enabled)
                .accessibilityLabel("Store path")
                .accessibilityValue(storePath)

            HStack(spacing: theme.spacing.sm) {
                Button("Open Terminal at Store") {
                    handleOpenTerminalTap()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Open Terminal at Store")
                .accessibilityHint("Opens Terminal.app at the password store location")

                Button("Dismiss") {
                    handleDismissTap()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Dismiss conflict banner")
                .accessibilityHint("Dismisses the merge conflict banner")
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    func handleOpenTerminalTap() {
        openTerminalAction()
        model.dismissGitConflictBanner()
    }

    func handleDismissTap() {
        model.dismissGitConflictBanner()
    }
}
