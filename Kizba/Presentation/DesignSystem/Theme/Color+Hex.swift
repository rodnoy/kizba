import SwiftUI

// DesignSystem-internal helper for constructing `Color` values from 24-bit
// hex literals. Used only by token constants in this folder; views must read
// colors through `Theme.colors`, not this initializer.
//
// We deliberately use `Color(red:green:blue:opacity:)` (sRGB) rather than
// `NSColor` to keep the helper portable and pure-SwiftUI.
extension Color {
    /// Initializes a color from a 24-bit hex value (`0xRRGGBB`).
    /// - Parameters:
    ///   - hex: 24-bit RGB value, e.g. `0xCDB4DB`.
    ///   - opacity: Alpha channel in `0...1`, defaulting to fully opaque.
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
