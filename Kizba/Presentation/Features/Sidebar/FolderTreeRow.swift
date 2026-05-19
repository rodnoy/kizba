//
//  FolderTreeRow.swift
//  Kizba
//
//  Recursive sidebar row for a single ``FolderNode``. Renders a flat
//  tappable row for leaf folders and a ``DisclosureGroup`` for
//  parents; child rows recurse through the same view with a visual
//  indent so the depth is obvious without a custom outline style.
//
//  Expansion state is persisted via the injected
//  ``FolderExpansionStoring`` so the tree reopens to the user's
//  arrangement across launches.
//

import SwiftUI

/// Sidebar row for a single ``FolderNode`` (MVP9.3).
///
/// The view is recursive: parent nodes embed nested ``FolderTreeRow``
/// instances inside a ``DisclosureGroup``; leaf nodes render a flat
/// row with the standard folder icon. Tapping any row writes the
/// node's ``FolderNode.fullPath`` into ``selectedPath`` — the entry
/// list reacts via its prefix-match filter (see
/// ``EntryListModel/entries``).
@MainActor
struct FolderTreeRow: View {

    let node: FolderNode
    let expansionStore: any FolderExpansionStoring
    @Binding var selectedPath: String?

    @State private var isExpanded: Bool = false
    @Environment(\.theme) private var theme

    var body: some View {
        if node.isLeaf {
            leafRow
                .listRowBackground(Color.clear)
        } else {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children) { child in
                    FolderTreeRow(
                        node: child,
                        expansionStore: expansionStore,
                        selectedPath: $selectedPath
                    )
                    .padding(.leading, theme.spacing.md)
                }
            } label: {
                labelRow
            }
            .listRowBackground(Color.clear)
            .onChange(of: isExpanded) { _, newValue in
                let store = expansionStore
                let path = node.fullPath
                Task { await store.setExpanded(path, expanded: newValue) }
            }
            .task {
                isExpanded = await expansionStore.isExpanded(node.fullPath)
            }
        }
    }

    /// Flat row for leaf folders (no chevron, no DisclosureGroup).
    private var leafRow: some View {
        EntryRowView(
            leadingIconName: "folder",
            title: node.name,
            isSelected: selectedPath == node.fullPath
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPath = node.fullPath
        }
        // I.3 a11y parity with the legacy flat sidebar row.
        .accessibilityLabel("\(node.name), folder")
    }

    /// Label row for parent folders (sits inside the DisclosureGroup).
    private var labelRow: some View {
        EntryRowView(
            leadingIconName: "folder",
            title: node.name,
            isSelected: selectedPath == node.fullPath
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPath = node.fullPath
        }
        .accessibilityLabel(
            "\(node.name), folder, \(isExpanded ? "expanded" : "collapsed")"
        )
    }
}
