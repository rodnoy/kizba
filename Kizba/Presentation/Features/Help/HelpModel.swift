//
//  HelpModel.swift
//  Kizba
//
//  `@MainActor`, `@Observable` view-model backing ``HelpView``. Owns
//  the catalog, the currently-selected topic, and the transient
//  "Copied ✓" flash state for code cards. Copy operations route
//  through the SHARED ``ClipboardServicing`` so future telemetry on
//  copy events flows through the same actor as secret copies.
//

import Foundation
import Observation

/// Presentation-layer view model for the Help window.
@MainActor
@Observable
public final class HelpModel {

    /// Retention duration passed to ``ClipboardServicing/copy(_:clearAfter:)``
    /// for every Help-driven copy. Help payloads are documentation
    /// commands, not secrets — a 10-minute window is comfortable for
    /// pasting into a terminal without interfering with the
    /// secret-copy auto-clear contract (which is governed by the
    /// user's clipboard delay setting and applied at the secret-copy
    /// call sites).
    public static let helpClipboardRetention: Duration = .seconds(600)

    /// All topics shown in the sidebar.
    public let topics: [HelpTopic]

    /// Sidebar selection. Defaults to the first topic at construction.
    public var selectedTopicID: HelpTopic.ID

    /// Block id whose code card is currently flashing "Copied ✓",
    /// or `nil` if no flash is active.
    public private(set) var copiedBlockID: HelpBlock.ID?

    /// How long the "Copied ✓" label stays before reverting to
    /// "Copy" / "Copy all". Injectable for tests so the flash-reset
    /// behaviour can be observed deterministically without real-time
    /// waits in production-flavoured tests.
    private let flashDuration: Duration

    private let clipboard: any ClipboardServicing
    private var flashResetTask: Task<Void, Never>?

    public init(
        clipboard: any ClipboardServicing,
        catalog: [HelpTopic] = HelpCatalog.all,
        flashDuration: Duration = .milliseconds(1500)
    ) {
        self.clipboard = clipboard
        self.topics = catalog
        self.flashDuration = flashDuration
        // Default to the first topic so the detail pane is never
        // empty when the window first opens. If the catalog is
        // empty (only possible in synthetic test wirings), fall
        // back to a sentinel id; ``selectedTopic`` will then
        // resolve to nil and ``HelpView`` shows the empty state.
        self.selectedTopicID = catalog.first?.id ?? ""
    }

    /// Topic matching ``selectedTopicID``, or `nil` if no such topic
    /// exists in the catalog.
    public var selectedTopic: HelpTopic? {
        topics.first(where: { $0.id == selectedTopicID })
    }

    /// Copy the joined `commands` string to the clipboard and flash
    /// the "Copied ✓" indicator on the originating block for
    /// ``flashDuration``. Repeated calls cancel any previous flash
    /// reset so the indicator stays visible across rapid clicks.
    ///
    /// - Parameters:
    ///   - commands: Lines to copy verbatim. Joined with `"\n"` so a
    ///     multi-line command sequence reaches the clipboard as a
    ///     single pasteable script.
    ///   - blockID: Identifier of the originating ``HelpBlock``.
    ///     Drives the per-card "Copied ✓" indicator.
    public func copy(commands: [String], for blockID: HelpBlock.ID) async {
        flashResetTask?.cancel()

        let payload = commands.joined(separator: "\n")
        await clipboard.copy(payload, clearAfter: HelpModel.helpClipboardRetention)

        copiedBlockID = blockID

        let duration = flashDuration
        flashResetTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard let self else { return }
            // Only clear if no later copy has stolen the flash slot.
            if self.copiedBlockID == blockID {
                self.copiedBlockID = nil
            }
        }
    }

    /// Convenience predicate so views can render their own
    /// "Copied ✓" affordance without inspecting ``copiedBlockID``
    /// directly.
    public func isCopied(blockID: HelpBlock.ID) -> Bool {
        copiedBlockID == blockID
    }
}
