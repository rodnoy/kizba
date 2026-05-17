//
//  HelpWarningCallout.swift
//  Kizba
//
//  Thin wrapper around ``BannerView`` with a fixed `.warning`
//  severity. Exists so call sites in ``HelpView`` read at the
//  semantics they care about ("warning callout") rather than at the
//  primitive level ("banner with severity x and title y").
//
//  The wrapper supplies a fixed title (`"Warning"`) so the underlying
//  banner contract — which requires a non-optional title — is
//  satisfied without leaking that requirement to ``HelpBlock``.
//

import SwiftUI

/// Inline warning callout used by the Help renderer. Always uses
/// `BannerView(severity: .warning)` so it inherits the design
/// system's color-blind-safe icon, contrast tokens, and divider
/// styling.
public struct HelpWarningCallout: View {

    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        BannerView(
            severity: .warning,
            title: "Warning",
            message: text,
            action: nil
        )
    }
}
