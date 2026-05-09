import SwiftUI

/// Sister modifier to `destructiveConfirmation` for non-destructive but
/// irreversible "Overwrite?" dialogs. Same shape, but the confirm
/// button uses the default role rather than `.destructive` because the
/// action does not delete data outright — it replaces an existing entry.
public extension View {
    func overwriteConfirmation(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmLabel: String = "Overwrite",
        confirm: @escaping @MainActor () -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(confirmLabel, action: confirm)
            Button("Cancel", role: .cancel) {}
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}
