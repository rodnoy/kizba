import SwiftUI

public struct OTPView: View {
    let model: OTPModel

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
