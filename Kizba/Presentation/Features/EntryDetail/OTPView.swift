import SwiftUI

public struct OTPView: View {
    let model: OTPModel

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MVP9.2 — reveal sheet state. The revealed string is held in
    // `@State` only for the lifetime of the sheet; on dismiss we
    // nil it out so the cleartext is not kept resident inside the
    // view tree.
    @State private var revealedURI: String?
    @State private var revealedSecret: String?
    @State private var revealedQRPayload: String?

    public init(model: OTPModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("One-time code")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)

            HStack(spacing: theme.spacing.md) {
                Text(groupedCode)
                    .font(theme.typography.mono)
                    .foregroundStyle(theme.colors.onSurface)
                    .textSelection(.enabled)

                Spacer()

                Button("Copy") {
                    Task { await model.requestCopy() }
                }
                .buttonStyle(.kizba(.ghost, size: .compact))
                .accessibilityLabel("Copy one-time code")
                .help("Copy current OTP code")

                // MVP9.2 — Export menu. Each item is gated through
                // BiometricGate via the corresponding `OTPModel`
                // reveal method; the model returns `nil` on
                // cancellation/failure and the sheet stays closed.
                Menu {
                    Button("Copy otpauth:// URI") {
                        Task {
                            if let uri = await model.revealURI() {
                                revealedURI = uri
                            }
                        }
                    }
                    Button("Copy manual secret") {
                        Task {
                            if let secret = await model.revealSecret() {
                                revealedSecret = secret
                            }
                        }
                    }
                    Button("Show QR code") {
                        Task {
                            if let payload = await model.revealQRPayload() {
                                revealedQRPayload = payload
                            }
                        }
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("Export OTP secret")
                .help("Export OTP secret (Touch ID required)")
            }

            if isHOTP {
                Text("HOTP (counter-based)")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
            } else if reduceMotion {
                Text("\(Int(max(0, floor(model.remainingSeconds))))s left")
                    .font(theme.typography.caption)
                    .foregroundStyle(progressTint)
            } else {
                HStack(spacing: theme.spacing.sm) {
                    ProgressView(value: model.progressFraction)
                        .tint(progressTint)
                    Text("\(Int(max(0, floor(model.remainingSeconds))))s")
                        .font(theme.typography.caption)
                        .foregroundStyle(progressTint)
                }
            }
        }
        // URI reveal sheet. `isPresented` is derived from the
        // optional `@State` — the sheet appears precisely while
        // the revealed string is non-nil. On dismiss we nil the
        // value so the cleartext export is dropped from view state.
        .sheet(isPresented: Binding(
            get: { revealedURI != nil },
            set: { if !$0 { revealedURI = nil } }
        )) {
            if let uri = revealedURI {
                OTPRevealSheet(
                    title: "OTP URI",
                    value: uri,
                    onCopy: { Task { await model.copyRevealedExport(uri) } },
                    onDismiss: { revealedURI = nil }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { revealedSecret != nil },
            set: { if !$0 { revealedSecret = nil } }
        )) {
            if let secret = revealedSecret {
                OTPRevealSheet(
                    title: "Manual secret",
                    value: secret,
                    onCopy: { Task { await model.copyRevealedExport(secret) } },
                    onDismiss: { revealedSecret = nil }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { revealedQRPayload != nil },
            set: { if !$0 { revealedQRPayload = nil } }
        )) {
            if let payload = revealedQRPayload {
                OTPQRSheet(
                    payload: payload,
                    onDismiss: { revealedQRPayload = nil }
                )
            }
        }
    }

    private var groupedCode: String {
        let chars = Array(model.currentCode)
        guard !chars.isEmpty else { return "" }

        var groups: [String] = []
        groups.reserveCapacity((chars.count + 2) / 3)
        var index = 0
        while index < chars.count {
            let end = min(index + 3, chars.count)
            groups.append(String(chars[index..<end]))
            index = end
        }
        return groups.joined(separator: " ")
    }

    private var progressTint: AnyShapeStyle {
        if model.remainingSeconds < 5 {
            return AnyShapeStyle(theme.colors.warning)
        }
        return AnyShapeStyle(theme.colors.accent)
    }

    private var isHOTP: Bool {
        model.remainingSeconds == 0 && model.progressFraction == 0
    }
}
