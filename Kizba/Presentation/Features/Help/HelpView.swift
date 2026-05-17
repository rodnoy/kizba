//
//  HelpView.swift
//  Kizba
//
//  Master/detail Help window content. The sidebar lists every topic
//  in ``HelpModel/topics``; the detail pane scrolls through the
//  selected topic's sections, dispatching each ``HelpBlock`` to the
//  matching presentation primitive (paragraph, warning callout,
//  code card, bulleted list).
//
//  When the model has no resolvable selected topic — only possible
//  in synthetic test wirings with an empty catalog — an
//  ``EmptyStateView`` is shown so the window never renders blank.
//

import SwiftUI

/// SwiftUI host for the Help window. Wires up the
/// `NavigationSplitView` between sidebar and detail and renders the
/// selected topic via the Help feature's primitive views.
public struct HelpView: View {

    @State private var model: HelpModel

    @Environment(\.theme) private var theme

    public init(model: HelpModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 720, minHeight: 480)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $model.selectedTopicID) {
            ForEach(model.topics) { topic in
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(topic.title)
                        .font(theme.typography.bodyEmphasized)
                        .foregroundStyle(theme.colors.onSurface)
                    if let subtitle = topic.subtitle {
                        Text(subtitle)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, theme.spacing.xs)
                .tag(topic.id)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Help")
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let topic = model.selectedTopic {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    header(for: topic)
                    ForEach(topic.sections) { section in
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            HelpSectionHeader(section.heading)
                            ForEach(section.body) { block in
                                renderBlock(block)
                            }
                        }
                    }
                }
                .padding(theme.spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.colors.surface)
        } else {
            EmptyStateView(
                iconName: "questionmark.circle",
                title: "No topic selected",
                message: "Pick a topic from the sidebar to see its content."
            )
        }
    }

    @ViewBuilder
    private func header(for topic: HelpTopic) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(topic.title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)
            if let subtitle = topic.subtitle {
                Text(subtitle)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: HelpBlock) -> some View {
        switch block {
        case let .paragraph(_, text):
            Text(LocalizedStringKey(text))
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

        case let .warning(_, text):
            HelpWarningCallout(text: text)

        case let .command(_, label, command, note):
            HelpCommandCard(
                label: label,
                commands: [command],
                note: note,
                isCopied: model.isCopied(blockID: block.id),
                onCopy: { [blockID = block.id, command] in
                    Task { await model.copy(commands: [command], for: blockID) }
                }
            )

        case let .commandSequence(_, label, commands, note):
            HelpCommandCard(
                label: label,
                commands: commands,
                note: note,
                isCopied: model.isCopied(blockID: block.id),
                onCopy: { [blockID = block.id, commands] in
                    Task { await model.copy(commands: commands, for: blockID) }
                }
            )

        case let .bulletList(_, items):
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Text("•")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.onSurfaceMuted)
                        Text(LocalizedStringKey(item))
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}
