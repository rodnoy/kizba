import SwiftUI

/// Typography scale. All entries are built from `Font.system(_ style:)` so
/// Dynamic Type continues to scale them; weights are layered on top via
/// `.weight(_:)` rather than fixed point sizes.
public struct TypographyTokens: Sendable, Equatable {
    public let display: Font
    public let title: Font
    public let headline: Font
    public let body: Font
    public let bodyEmphasized: Font
    public let callout: Font
    public let caption: Font
    public let mono: Font
    public let monoSmall: Font

    public init(
        display: Font,
        title: Font,
        headline: Font,
        body: Font,
        bodyEmphasized: Font,
        callout: Font,
        caption: Font,
        mono: Font,
        monoSmall: Font
    ) {
        self.display = display
        self.title = title
        self.headline = headline
        self.body = body
        self.bodyEmphasized = bodyEmphasized
        self.callout = callout
        self.caption = caption
        self.mono = mono
        self.monoSmall = monoSmall
    }

    public static let `default` = TypographyTokens(
        display: .system(.largeTitle, design: .default).weight(.bold),
        title: .system(.title, design: .default).weight(.semibold),
        headline: .system(.headline),
        body: .system(.body),
        bodyEmphasized: .system(.body).weight(.semibold),
        callout: .system(.callout),
        caption: .system(.caption),
        mono: .system(.body, design: .monospaced),
        monoSmall: .system(.caption, design: .monospaced)
    )
}
