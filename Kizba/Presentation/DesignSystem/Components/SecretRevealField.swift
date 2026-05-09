import SwiftUI

/// Read-only display for a secret value with reveal toggle and copy
/// action. Uses the monospaced typography so each character is read
/// distinctly when revealed; background composes `secretMask` over
/// `surface` so the mask reads as an overlay even when the host theme
/// uses an opaque surface.
///
/// Security: the view never logs or prints `value`. The same grep bans
/// that protect the Infrastructure layer apply to DesignSystem files.
public struct SecretRevealField: View {
    private let value: String
    private let label: String?
    @Binding private var isRevealed: Bool
    private let onCopy: @MainActor () -> Void
    private let copyButtonLabel: String

    public init(
        value: String,
        label: String? = nil,
        isRevealed: Binding<Bool>,
        onCopy: @escaping @MainActor () -> Void,
        copyButtonLabel: String = "Copy"
    ) {
        self.value = value
        self.label = label
        self._isRevealed = isRevealed
        self.onCopy = onCopy
        self.copyButtonLabel = copyButtonLabel
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }

            HStack(spacing: theme.spacing.sm) {
                Text(SecretRevealField.displayText(for: value, isRevealed: isRevealed))
                    .font(theme.typography.mono)
                    .foregroundStyle(theme.colors.onSurface)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(isRevealed ? value : "Hidden secret")

                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                }
                .buttonStyle(.kizba(.ghost, size: .compact))
                .accessibilityLabel(isRevealed ? "Hide secret" : "Reveal secret")

                Button(copyButtonLabel, action: onCopy)
                    .buttonStyle(.kizba(.ghost, size: .compact))
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .fill(theme.colors.surface)
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .fill(theme.colors.secretMask)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(theme.colors.divider, lineWidth: 1)
            )
        }
    }

    // MARK: - Pure helpers (testable contract)

    /// Length used for the masked placeholder. Clamped to `[8, 32]` so the
    /// rendered field always has visible content but never hints at the
    /// real secret length.
    static func maskedLength(for value: String) -> Int {
        max(8, min(value.count, 32))
    }

    /// Returns either the value itself (revealed) or a bullet-mask string
    /// of `maskedLength(for:)` characters.
    static func displayText(for value: String, isRevealed: Bool) -> String {
        if isRevealed {
            return value
        }
        return String(repeating: "•", count: maskedLength(for: value))
    }
}
