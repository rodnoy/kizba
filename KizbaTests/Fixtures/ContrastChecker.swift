//
//  ContrastChecker.swift
//  KizbaTests
//
//  Test-only helper. Do NOT use from production code.
//
//  Pure-function utility for measuring WCAG 2.1 contrast ratios between
//  SwiftUI `Color` values. Used by `ThemeTokenTests` to lock the design
//  system's contrast policy in code (AA body, AAA on-surface, focus-ring
//  3:1 minimum, etc.).
//
//  The math is performed in linear sRGB after extracting RGB components
//  via `NSColor(<color>).usingColorSpace(.sRGB)`. macOS-only is fine —
//  the entire app is macOS-only and this file lives in the test target.
//
//  Alpha handling: WCAG ratios are only defined for opaque colors. When a
//  token carries `opacity < 1` (e.g. `surfaceHover = #cdb4db @ 0.14`),
//  callers must composite it over an opaque base (typically `surface`)
//  before measuring. The `alphaCompositedOver:` overload does exactly
//  that, using straight-alpha compositing in linear-sRGB space.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

/// Pure WCAG 2.1 contrast utility. No state, no side effects, no production
/// callers — invoked solely from `ThemeTokenTests`.
enum ContrastChecker {

    // MARK: - Public API

    /// Returns the WCAG 2.1 relative luminance of `color` after resolving
    /// to sRGB. Values are in `[0, 1]`. Alpha is ignored — callers must
    /// composite first if the color is translucent.
    static func relativeLuminance(_ color: Color) -> Double {
        let rgba = sRGBComponents(of: color)
        let r = srgbToLinear(rgba.red)
        let g = srgbToLinear(rgba.green)
        let b = srgbToLinear(rgba.blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Returns the WCAG 2.1 contrast ratio `(L1 + 0.05) / (L2 + 0.05)`
    /// where `L1 = max(luminance)` and `L2 = min(luminance)`. Always
    /// `>= 1.0`. For opaque colors only — see the `alphaCompositedOver`
    /// overload for translucent tokens.
    static func contrastRatio(foreground: Color, background: Color) -> Double {
        let l1 = relativeLuminance(foreground)
        let l2 = relativeLuminance(background)
        let hi = max(l1, l2)
        let lo = min(l1, l2)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// Convenience for measuring contrast when one or both inputs may be
    /// translucent. Both `foreground` and `background` are composited over
    /// `opaque` first, then the standard ratio is computed against the
    /// resulting opaque colors.
    ///
    /// In practice tests pass `opaque = theme.colors.surface` so that
    /// overlay tokens (`surfaceHover`, `secretMask`, …) are evaluated
    /// against the same base they will render against in the UI.
    static func contrastRatio(
        foreground: Color,
        background: Color,
        alphaCompositedOver opaque: Color
    ) -> Double {
        let fg = compositeOver(foreground, opaque)
        let bg = compositeOver(background, opaque)
        return contrastRatio(foreground: fg, background: bg)
    }

    /// Standard "source-over" alpha compositing in linear-sRGB space.
    /// Returns an opaque `Color` (alpha = 1) representing how `foreground`
    /// would look painted on top of `background`.
    ///
    /// The composite is computed in linear space because that's where
    /// physical light addition is correct; the result is then re-encoded
    /// to gamma sRGB so the returned `Color` round-trips through the
    /// `sRGBComponents(of:)` path used by `relativeLuminance`.
    static func compositeOver(_ foreground: Color, _ background: Color) -> Color {
        let fg = sRGBComponents(of: foreground)
        let bg = sRGBComponents(of: background)

        // Promote the background to fully opaque before compositing —
        // this matches how UI surfaces work in practice (the bottom-most
        // layer is always opaque) and keeps the helper composable.
        let fgA = fg.alpha
        let bgA = 1.0

        let fr = srgbToLinear(fg.red)
        let fgg = srgbToLinear(fg.green)
        let fb = srgbToLinear(fg.blue)
        let br = srgbToLinear(bg.red)
        let bgn = srgbToLinear(bg.green)
        let bb = srgbToLinear(bg.blue)

        let outA = fgA + bgA * (1 - fgA) // == 1.0
        let outR = (fr * fgA + br * bgA * (1 - fgA)) / outA
        let outG = (fgg * fgA + bgn * bgA * (1 - fgA)) / outA
        let outB = (fb * fgA + bb * bgA * (1 - fgA)) / outA

        return Color(
            .sRGB,
            red: linearToSrgb(outR),
            green: linearToSrgb(outG),
            blue: linearToSrgb(outB),
            opacity: 1.0
        )
    }

    // MARK: - Internals

    /// sRGB-encoded RGBA components in `[0, 1]`. Crashes loudly in tests
    /// (via `fatalError`) if the platform cannot produce a sRGB
    /// representation — that would indicate a misconfigured `Color` and
    /// every downstream contrast measurement would be meaningless.
    private struct RGBA: Sendable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
    }

    private static func sRGBComponents(of color: Color) -> RGBA {
        #if canImport(AppKit)
        let ns = NSColor(color)
        guard let srgb = ns.usingColorSpace(.sRGB) else {
            fatalError("ContrastChecker: cannot resolve color to sRGB: \(color)")
        }
        return RGBA(
            red: Double(srgb.redComponent),
            green: Double(srgb.greenComponent),
            blue: Double(srgb.blueComponent),
            alpha: Double(srgb.alphaComponent)
        )
        #else
        fatalError("ContrastChecker requires AppKit (macOS-only test target).")
        #endif
    }

    /// WCAG 2.1 sRGB → linear-light transfer function.
    private static func srgbToLinear(_ channel: Double) -> Double {
        if channel <= 0.04045 {
            return channel / 12.92
        }
        return pow((channel + 0.055) / 1.055, 2.4)
    }

    /// Inverse of `srgbToLinear`. Used to re-encode composited colors
    /// back into the gamma-sRGB space that `Color(.sRGB, …)` expects.
    private static func linearToSrgb(_ channel: Double) -> Double {
        let clamped = min(max(channel, 0), 1)
        if clamped <= 0.0031308 {
            return 12.92 * clamped
        }
        return 1.055 * pow(clamped, 1.0 / 2.4) - 0.055
    }
}
