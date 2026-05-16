import Foundation
import SwiftUI

#if canImport(AppKit)
import AppKit

@MainActor
final class StatusItemController: NSObject {

    private var statusItem: NSStatusItem?
    private let popover: NSPopover
    private let content: () -> AnyView

    init(environment: AppEnvironment, content: @escaping () -> AnyView) {
        self.content = content
        _ = environment

        let popover = NSPopover()
        popover.animates = false
        popover.behavior = .transient
        popover.appearance = NSApp?.effectiveAppearance
        self.popover = popover

        super.init()

        configurePopoverContent()
    }

    func show() {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = item.button {
                if let image = NSImage(
                    systemSymbolName: "key.fill",
                    accessibilityDescription: "Kizba"
                ) {
                    image.isTemplate = true
                    button.image = image
                } else {
                    button.title = "Kizba"
                }
                button.target = self
                button.action = #selector(handleStatusItemButtonAction)
            }
            statusItem = item
        }

        configurePopoverContent()
    }

    func hide() {
        popover.performClose(nil)
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    func toggle() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }

        if statusItem == nil {
            show()
        }

        showPopover()
    }

    deinit {
        MainActor.assumeIsolated {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
            }
        }
    }

    @objc
    private func handleStatusItemButtonAction() {
        toggle()
    }

    private func configurePopoverContent() {
        let viewController = NSViewController()
        viewController.view = NSHostingView(rootView: content())
        popover.contentViewController = viewController
        popover.appearance = NSApp?.effectiveAppearance
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

#else

@MainActor
final class StatusItemController {
    init(environment: AppEnvironment, content: @escaping () -> AnyView) {
        _ = environment
        _ = content
    }

    func show() {}

    func hide() {}

    func toggle() {}
}

#endif
