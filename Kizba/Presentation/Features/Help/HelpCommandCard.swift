//
//  HelpCommandCard.swift
//  Kizba
//
//  Code card with a copy button used by the Help renderer for both
//  ``HelpBlock/command`` and ``HelpBlock/commandSequence`` cases.
//  The card itself is a ``KizbaCard`` wrapping monospaced text;
//  the copy button uses the secondary `KizbaButtonStyle` and adopts
//  a transient "Copied ✓" label driven by `isCopied`.
//
//  Visual / label decisions are factored into `internal static`
//  pure helpers (``copyButtonLabel(commandCount:isCopied:)`` and
//  ``copyButtonAccessibilityLabel(commands:)``) so they can be
//  asserted from XCTest without rendering the SwiftUI hierarchy —
//  matching the project's "pure-helper view test pattern".
//

import SwiftUI

/// Code card rendering one or more commands with a copy button.
public struct HelpCommandCard: View {

    private let label: String?
    private let commands: [String]
    private let note: String?
    private let isCopied: Bool
    private let onCopy: () -> Void

    @Environment(\.theme) private var theme

    public init(
        label: String?,
        commands: [String],
        note: String?,
        isCopied: Bool,
        onCopy: @escaping () -> Void
    ) {
        self.label = label
        self.commands = commands
        self.note = note
        self.isCopied = isCopied
        self.onCopy = onCopy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            }

            KizbaCard {
                HStack(alignment: .top, spacing: theme.spacing.md) {
                    Text(commands.joined(separator: "\n"))
                        .font(theme.typography.mono)
                        .foregroundStyle(theme.colors.onSurface)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        onCopy()
                    } label: {
                        Text(
                            HelpCommandCard.copyButtonLabel(
                                commandCount: commands.count,
                                isCopied: isCopied
                            )
                        )
                    }
                    .buttonStyle(.kizba(.secondary, size: .compact))
                    .accessibilityLabel(
                        HelpCommandCard.copyButtonAccessibilityLabel(commands: commands)
                    )
                }
            }

            if let note {
                Text(note)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Pure helpers (testable contract)

    /// Visible label for the copy button. Mirrors the spec:
    ///   - flashing "Copied ✓" wins regardless of count;
    ///   - single-command cards say "Copy";
    ///   - multi-command cards say "Copy all".
    static func copyButtonLabel(commandCount: Int, isCopied: Bool) -> String {
        if isCopied {
            return "Copied ✓"
        }
        if commandCount <= 1 {
            return "Copy"
        }
        return "Copy all"
    }

    /// VoiceOver-friendly label for the copy button. Discloses the
    /// single command verbatim when present, or the count for
    /// multi-command cards.
    static func copyButtonAccessibilityLabel(commands: [String]) -> String {
        if commands.isEmpty {
            // Safe fallback — the real catalog never produces an
            // empty command array, but the helper stays defined for
            // every input.
            return "Copy"
        }
        if commands.count == 1 {
            return "Copy command: \(commands[0])"
        }
        return "Copy commands (\(commands.count))"
    }
}
