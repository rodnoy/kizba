//
//  OTPRevealSheet.swift
//  Kizba
//
//  MVP9.2 — sheet used to display the result of a Touch-ID-gated
//  reveal (otpauth:// URI or raw Base32 secret) with an in-sheet
//  Copy button that routes through `OTPModel.copyRevealedExport(_:)`
//  so it inherits the standard clipboard auto-clear discipline.
//
//  The revealed value is held in the parent view's `@State` and
//  passed in here; the sheet does not retain it beyond its own
//  presentation. On dismiss the parent nils its `@State` so the
//  cleartext export is not kept resident.
//

import SwiftUI

struct OTPRevealSheet: View {
    let title: String
    let value: String
    /// Callback invoked when the user taps Copy. The parent (the
    /// `OTPView`) routes this through `OTPModel.copyRevealedExport`
    /// so the export inherits the clipboard auto-clear window.
    let onCopy: @MainActor () -> Void
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Text(title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)

            ScrollView {
                Text(value)
                    .font(theme.typography.mono)
                    .foregroundStyle(theme.colors.onSurface)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(theme.spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                            .fill(theme.colors.surfaceSunken)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                            .strokeBorder(theme.colors.divider, lineWidth: 1)
                    )
            }
            .frame(maxHeight: 160)

            Text("This is the underlying secret. Anyone with this value can generate codes for this account.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: theme.spacing.sm) {
                Button("Copy") {
                    onCopy()
                }
                .buttonStyle(.kizba(.secondary))

                Spacer()

                Button("Done", action: onDismiss)
                    .buttonStyle(.kizba(.primary))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(theme.spacing.xl)
        .frame(minWidth: 460)
    }
}
