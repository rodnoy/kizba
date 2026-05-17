//
//  HelpTopic.swift
//  Kizba
//
//  Plain-data domain types backing the Help feature. The catalog is a
//  static, immutable tree of `HelpTopic` → `HelpSection` → `HelpBlock`
//  values that the SwiftUI layer renders without performing any
//  identity computation of its own. Block / section identifiers are
//  assigned by the catalog so identity is stable across rebuilds and
//  trivially testable.
//
//  Pure value types, no SwiftUI import — keeps the model usable from
//  unit tests without dragging the framework along.
//

import Foundation

/// One Help topic shown in the master/detail navigation. Topics are
/// the unit of selection in the sidebar and the unit of content in
/// the detail pane.
public struct HelpTopic: Identifiable, Hashable, Sendable {

    /// Stable, human-readable identifier (e.g. `"aead-mdc-compatibility"`).
    /// Used both as `Identifiable.id` and as the prefix of every
    /// section / block id under this topic.
    public let id: String

    /// Sidebar-visible title.
    public let title: String

    /// Optional one-liner shown under the title in the detail header.
    public let subtitle: String?

    /// Ordered sections rendered in the detail pane.
    public let sections: [HelpSection]

    public init(id: String, title: String, subtitle: String?, sections: [HelpSection]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.sections = sections
    }
}

/// A heading-and-body chunk inside a `HelpTopic`. Sections are the
/// logical grouping for the detail pane's vertical scroll.
public struct HelpSection: Hashable, Sendable, Identifiable {

    /// Deterministic id assigned by the catalog as
    /// `"<topicID>/<sectionIndex>"`.
    public let id: String

    /// Section heading rendered above the body via
    /// ``HelpSectionHeader``.
    public let heading: String

    /// Ordered renderable blocks.
    public let body: [HelpBlock]

    public init(id: String, heading: String, body: [HelpBlock]) {
        self.id = id
        self.heading = heading
        self.body = body
    }
}

/// A single renderable item inside a `HelpSection`.
///
/// Each case carries its own deterministic id (assigned by the catalog
/// as `"<topicID>/<sectionIndex>/<blockIndex>"`) so the SwiftUI layer
/// can use `ForEach` without computing identity inline.
public enum HelpBlock: Hashable, Sendable, Identifiable {

    /// Plain prose paragraph.
    case paragraph(id: String, text: String)

    /// Inline warning callout. Rendered via ``HelpWarningCallout`` /
    /// ``BannerView`` with `.warning` severity.
    case warning(id: String, text: String)

    /// A single shell command rendered in a copyable code card.
    case command(id: String, label: String?, command: String, note: String?)

    /// An ordered sequence of related shell commands rendered as a
    /// single multi-line code card. The "Copy" button copies the
    /// commands joined with `"\n"` so the user receives the script
    /// verbatim.
    case commandSequence(id: String, label: String?, commands: [String], note: String?)

    /// Bulleted list of short items.
    case bulletList(id: String, items: [String])

    /// Stable id derived from the case payload. Matches the value the
    /// catalog assigned at construction time.
    public var id: String {
        switch self {
        case let .paragraph(id, _): return id
        case let .warning(id, _): return id
        case let .command(id, _, _, _): return id
        case let .commandSequence(id, _, _, _): return id
        case let .bulletList(id, _): return id
        }
    }
}
