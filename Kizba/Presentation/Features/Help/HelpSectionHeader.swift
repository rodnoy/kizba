//
//  HelpSectionHeader.swift
//  Kizba
//
//  Themed section heading for the Help detail pane. Lives in the
//  Help feature folder rather than DesignSystem because its semantic
//  weight is "Help section title" rather than a generic primitive;
//  if a second feature ever needs the same shape, this can be
//  promoted upwards.
//

import SwiftUI

/// Bold themed text rendered above each ``HelpSection`` body.
public struct HelpSectionHeader: View {

    private let text: String

    @Environment(\.theme) private var theme

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(theme.typography.headline)
            .foregroundStyle(theme.colors.onSurface)
            .accessibilityAddTraits(.isHeader)
    }
}
