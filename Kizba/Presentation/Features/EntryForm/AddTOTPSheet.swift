//
//  AddTOTPSheet.swift
//  Kizba
//
//  MVP9.2 — sheet hosted by `EntryFormBody`'s "One-time password"
//  section. Lets the user attach a TOTP secret to the entry under
//  edit via one of four input methods (the canonical UX-locked set
//  for MVP9.2):
//
//    1. Generate random — 160-bit CryptoKit CSPRNG.
//    2. From passphrase — deterministic SHA-256 (UI shows a warning
//       that the same passphrase always produces the same code).
//    3. Paste otpauth:// URI — for moving a secret from another
//       authenticator app via clipboard.
//    4. Type secret manually — Base32 with normalisation.
//
//  Deferred from MVP9.2 scope: "Import from QR code (camera or
//  picture)" — requires Vision framework + AVCaptureDevice / camera
//  permission, which is a separate scope.
//
//  On submission the sheet hands the resulting `OTPSecret` to its
//  parent, which appends it as a `MetadataPair(key: "otpauth", ...)`
//  on the draft (Convention #1 of `OTPDiscovery`). The sheet does
//  not touch the draft itself — the parent owns the storage shape.
//

import SwiftUI

/// One of the four user-facing methods for attaching a TOTP secret
/// to an entry under edit. Ordering is the same as the segmented
/// picker so test code can address them by `allCases` index.
enum AddTOTPMethod: String, CaseIterable, Identifiable {
    case generateRandom
    case passphrase
    case pasteURI
    case typeSecret

    var id: String { rawValue }

    var label: String {
        switch self {
        case .generateRandom: return "Random"
        case .passphrase:     return "Passphrase"
        case .pasteURI:       return "Paste URI"
        case .typeSecret:     return "Type secret"
        }
    }
}

struct AddTOTPSheet: View {

    // MARK: - Inputs

    /// Best-effort default issuer (e.g. derived from the entry path).
    /// `nil` means "no prefill"; the user can still type a value.
    let defaultIssuer: String?

    /// Best-effort default account/label.
    let defaultLabel: String?

    /// Invoked with the validated `OTPSecret` when the user taps Add.
    let onAdd: (OTPSecret) -> Void

    /// Invoked when the user taps Cancel or otherwise dismisses.
    let onCancel: () -> Void

    // MARK: - Local state

    @State private var method: AddTOTPMethod = .generateRandom
    @State private var issuer: String = ""
    @State private var label: String = ""

    @State private var passphrase: String = ""
    @State private var pastedURI: String = ""
    @State private var typedSecret: String = ""

    /// Inline validation message shown above the footer when a
    /// submission fails. Cleared on every method switch and on the
    /// next Add attempt.
    @State private var errorMessage: String?

    @Environment(\.theme) private var theme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            Text("Add one-time password")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)

            // Method picker — segmented so the four options are
            // immediately visible without expanding a dropdown.
            Picker("Method", selection: $method) {
                ForEach(AddTOTPMethod.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: method) { _, _ in
                errorMessage = nil
            }

            // Common fields: issuer + account. Both optional; the
            // builder falls back to a placeholder label when neither
            // is set so the URI stays well-formed.
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                labeledField(caption: "Issuer (optional)", placeholder: "e.g. GitHub", text: $issuer)
                labeledField(caption: "Account (optional)", placeholder: "e.g. alice@example.com", text: $label)
            }

            Divider()

            methodInput

            if let errorMessage {
                Text(errorMessage)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.danger)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.kizba(.ghost))
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Add", action: handleAdd)
                    .buttonStyle(.kizba(.primary))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(theme.spacing.xl)
        .frame(minWidth: 480)
        .onAppear {
            // Prefill only on first appearance. Subsequent re-renders
            // must not stomp on whatever the user has typed.
            if issuer.isEmpty, let defaultIssuer { issuer = defaultIssuer }
            if label.isEmpty, let defaultLabel { label = defaultLabel }
        }
    }

    // MARK: - Method-specific input

    @ViewBuilder
    private var methodInput: some View {
        switch method {
        case .generateRandom:
            Text("A fresh 160-bit secret will be generated using the system CSPRNG.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .fixedSize(horizontal: false, vertical: true)

        case .passphrase:
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Passphrase")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                SecureField("Enter a word or phrase", text: $passphrase)
                    .textFieldStyle(.kizba)
                Text("Deterministic: the same passphrase always produces the same code. Use this only when you need a portable, re-derivable secret — random is otherwise stronger.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .pasteURI:
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("otpauth:// URI")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                TextField("otpauth://totp/Issuer:Account?secret=...", text: $pastedURI)
                    .textFieldStyle(.kizba)
            }

        case .typeSecret:
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Base32 secret")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                TextField("JBSWY3DPEHPK3PXP", text: $typedSecret)
                    .textFieldStyle(.kizba)
                Text("RFC 4648 alphabet only (A–Z and 2–7). Spaces and padding are stripped automatically.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func labeledField(caption: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(caption)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.onSurfaceMuted)
            TextField(placeholder, text: text)
                .textFieldStyle(.kizba)
        }
    }

    // MARK: - Submission

    private func handleAdd() {
        errorMessage = nil

        let trimmedIssuer = issuer.trimmingCharacters(in: .whitespaces)
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)
        let finalIssuer: String? = trimmedIssuer.isEmpty ? nil : trimmedIssuer
        let finalLabel: String? = trimmedLabel.isEmpty ? nil : trimmedLabel

        switch Self.buildSecret(
            method: method,
            issuer: finalIssuer,
            label: finalLabel,
            passphrase: passphrase,
            pastedURI: pastedURI,
            typedSecret: typedSecret
        ) {
        case .success(let secret):
            onAdd(secret)
        case .failure(let error):
            errorMessage = error.message
        }
    }

    // MARK: - Pure helpers (testable contract)

    /// Submission errors surfaced inline above the footer. Kept
    /// pure / `Equatable` so tests can pin down which validation
    /// path a given input takes.
    enum SubmissionError: Error, Equatable {
        case emptyPassphrase
        case invalidURI(String)
        case invalidBase32

        var message: String {
            switch self {
            case .emptyPassphrase:
                return "Passphrase cannot be empty."
            case .invalidURI(let detail):
                if detail.isEmpty { return "Invalid otpauth:// URI." }
                return "Invalid otpauth:// URI: \(detail)"
            case .invalidBase32:
                return "Invalid Base32 secret. Use only A–Z and 2–7."
            }
        }
    }

    /// Pure (no `@MainActor`, no view state) version of the Add
    /// pipeline. Exposed `internal` so tests can drive every method
    /// branch without instantiating SwiftUI.
    static func buildSecret(
        method: AddTOTPMethod,
        issuer: String?,
        label: String?,
        passphrase: String,
        pastedURI: String,
        typedSecret: String
    ) -> Result<OTPSecret, SubmissionError> {
        switch method {
        case .generateRandom:
            return .success(OTPSecretGenerator.random(label: label, issuer: issuer))

        case .passphrase:
            // The generator itself accepts the empty string (SHA-256
            // of "" is well-defined), but the UI requires non-empty
            // input — an empty passphrase means "the user has not
            // committed", not "use an empty passphrase".
            guard !passphrase.isEmpty else { return .failure(.emptyPassphrase) }
            return .success(OTPSecretGenerator.fromPassphrase(passphrase, label: label, issuer: issuer))

        case .pasteURI:
            do {
                var parsed = try OTPAuthURIParser.parse(pastedURI)
                // Honour issuer/label override when the user has
                // typed something in the common fields. Empty
                // overrides fall through to whatever the URI itself
                // carried.
                if issuer != nil || label != nil {
                    parsed = OTPSecret(
                        kind: parsed.kind,
                        secretBase32: parsed.secretBase32,
                        algorithm: parsed.algorithm,
                        digits: parsed.digits,
                        label: label ?? parsed.label,
                        issuer: issuer ?? parsed.issuer
                    )
                }
                return .success(parsed)
            } catch {
                return .failure(.invalidURI(String(describing: error)))
            }

        case .typeSecret:
            guard let secret = OTPSecretGenerator.fromBase32(typedSecret, label: label, issuer: issuer) else {
                return .failure(.invalidBase32)
            }
            return .success(secret)
        }
    }
}
