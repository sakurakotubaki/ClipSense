//
//  StatusBarController.swift
//  ClipSense
//

import AppKit
import SwiftData
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(modelContainer: ModelContainer, history: ClipboardHistoryModel) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.contentViewController = NSHostingController(
            rootView: ClipboardHistoryView(model: history)
                .modelContainer(modelContainer)
        )

        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipSense")
            button.action = #selector(togglePopoverFromStatusItem)
            button.target = self
        }
    }

    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() {
        popover.performClose(nil)
    }

    @objc private func togglePopoverFromStatusItem() {
        togglePopover()
    }
}
