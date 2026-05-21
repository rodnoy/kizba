import SwiftUI

struct GitStatusBadge: View {

    let model: GitStatusModel

    @State private var isPopoverPresented = false
    @Environment(\.theme) private var theme

    var body: some View {
        Button {
            isPopoverPresented.toggle()
        } label: {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: sfSymbolName)
                    .accessibilityHidden(true)
                Text(model.badgeText)
                    .font(theme.typography.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .popover(isPresented: $isPopoverPresented) {
            // MVP4 fix-pack v1, Fix 2 — explicitly wire EVERY action.
            // Forgetting any of these is now a compile error
            // (closures are required parameters).
            GitActionsPopover(
                model: model,
                onPull: { await model.pull() },
                onPush: { await model.push() },
                onRefresh: { await model.fetchAndReloadStatus() },
                onCancel: { model.cancelOperation() },
                onOpenTerminal: { model.openTerminalAtStore() }
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.badgeAccessibilityLabel)
        .accessibilityValue(model.badgeText)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens git actions")
        .help("Git status: \(model.badgeText) — open git actions")
    }

    private var sfSymbolName: String {
        guard model.status.isGitRepository else { return "minus.circle" }
        if model.status.hasConflicts { return "exclamationmark.triangle" }
        if model.status.aheadCount > 0, model.status.behindCount > 0 { return "arrow.up.arrow.down.circle" }
        if model.status.aheadCount > 0 { return "arrow.up.circle" }
        if model.status.behindCount > 0 { return "arrow.down.circle" }
        if model.status.hasLocalChanges { return "pencil.circle" }
        return "checkmark.circle"
    }

    private var foregroundColor: Color {
        guard model.status.isGitRepository else { return theme.colors.onSurfaceMuted }
        if model.status.hasConflicts { return theme.colors.danger }
        if model.status.hasLocalChanges { return theme.colors.warning }
        if model.status.aheadCount > 0 || model.status.behindCount > 0 { return theme.colors.accent }
        return theme.colors.onSurfaceMuted
    }
}
