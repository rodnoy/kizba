import SwiftUI

/// Two-step destructive confirmation modifier. Per `.ai/decisions.md`,
/// destructive operations (delete, etc.) gate behind a system
/// `confirmationDialog` with the destructive role on the confirm button;
/// Escape cancels. The system dialog handles its own theming, so no
/// `KizbaButtonStyle` wrapping is needed inside the dialog actions.
public extension View {
    func destructiveConfirmation(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmLabel: String = "Delete",
        confirm: @escaping @MainActor () -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(confirmLabel, role: .destructive, action: confirm)
            Button("Cancel", role: .cancel) {}
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}
