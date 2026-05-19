//
//  OTPQRSheet.swift
//  Kizba
//
//  MVP9.2 — sheet that displays the OTP secret as a QR code so the
//  user can enrol it in another authenticator app (Google
//  Authenticator, 1Password, Bitwarden, ...). The payload itself is
//  the secret, which is why the parent `OTPView` only opens this
//  sheet after a successful Touch-ID-gated reveal.
//
//  The QR rendering lives in `QRCodeImage` (DesignSystem). This
//  sheet is the lightweight chrome around it.
//

import SwiftUI

struct OTPQRSheet: View {
    let payload: String
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("OTP QR code")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)

            QRCodeImage(payload: payload, size: 260)

            Text("Scan with another authenticator app to enrol this account. Anyone with this code can generate logins for it.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 280)

            Button("Done", action: onDismiss)
                .buttonStyle(.kizba(.primary))
                .keyboardShortcut(.defaultAction)
        }
        .padding(theme.spacing.xl)
        .frame(minWidth: 360)
    }
}
