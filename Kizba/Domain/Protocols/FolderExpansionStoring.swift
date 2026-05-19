import Foundation

/// Persistent storage for the sidebar's per-folder expansion state.
///
/// Backs ``FolderTreeRow`` so each ``DisclosureGroup`` reopens to the
/// state the user left it in. State is keyed by a folder's
/// ``FolderNode.fullPath`` (no leading or trailing slash).
public protocol FolderExpansionStoring: Sendable {

    /// Returns `true` when the folder at ``folderPath`` is recorded as
    /// expanded. Folders unknown to the store default to collapsed.
    func isExpanded(_ folderPath: String) async -> Bool

    /// Persist the expansion state for ``folderPath``. Setting the
    /// same state twice is a no-op (and emits no change notification).
    func setExpanded(_ folderPath: String, expanded: Bool) async

    /// Emits after every successful mutation. Subscribers re-read the
    /// state of the folders they care about (the stream carries no
    /// payload — it is a fan-out wake-up signal).
    var folderExpansionChanged: AsyncStream<Void> { get }
}
