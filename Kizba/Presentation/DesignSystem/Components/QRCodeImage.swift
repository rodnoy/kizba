//
//  QRCodeImage.swift
//  Kizba
//
//  MVP9.2 — DesignSystem QR code renderer used by the OTP export
//  sheet. Wraps Apple's CoreImage `CIFilter.qrCodeGenerator()`
//  so we ship no third-party dependency.
//
//  Why this lives in DesignSystem:
//    The component intentionally renders on a hard white surface
//    behind the QR pixels. White is critical for scanner contrast
//    (the spec encodes data as dark modules on a light background),
//    so the inline `Color.white` lives here where the Phase C.6
//    `Color.*` ban is scoped out (DesignSystem is the single source
//    of truth for raw SwiftUI primitives).
//
//  Behaviour:
//    - `.interpolation(.none)` keeps the 1px modules razor sharp
//      after the 10x affine scale; the `.scaledToFit()` then maps
//      the result into `size`.
//    - A small white quiet-zone padding is added so the symbol meets
//      the reader-required margin without callers having to wrap
//      the view themselves.
//    - On filter / context failure we fall back to a sunken
//      placeholder so the surrounding layout does not collapse.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

public struct QRCodeImage: View {
    public let payload: String
    public let size: CGFloat

    @Environment(\.theme) private var theme

    public init(payload: String, size: CGFloat = 220) {
        self.payload = payload
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Hard white background per the QR spec (dark modules on
            // light background). The radius lives at the call site
            // via `.clipShape(...)` if a card-style framing is
            // needed; this view ships flat so it composes equally
            // well inside cards and inside chrome-less sheets.
            Color.white

            if let image = Self.generate(payload: payload) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(theme.spacing.sm) // quiet zone
            } else {
                // Filter / context failure path — keep the slot
                // visible so the parent layout does not jump and
                // the caller can render an explanatory caption.
                Rectangle()
                    .fill(theme.colors.surfaceSunken)
                    .padding(theme.spacing.sm)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("QR code")
    }

    // MARK: - Image generation

    /// Build an `NSImage` from `payload` using CoreImage's QR
    /// generator. Pure / no UI dependency so it stays unit-testable.
    /// Returns `nil` when CoreImage refuses the input (oversized
    /// payload, encoding failure).
    static func generate(payload: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        // "M" balances density vs. scan reliability — same level
        // commonly used by Google Authenticator's export feature.
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }

        // Scale up before rasterising so the resulting bitmap has
        // crisp module edges before SwiftUI's resize logic touches
        // it. 10x matches Apple's CoreImage sample code.
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: scaled.extent.width, height: scaled.extent.height)
        )
    }
}
