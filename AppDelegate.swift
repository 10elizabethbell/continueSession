import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private let viewModel = PopoverViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: nil)
            btn.action = #selector(togglePopover)
            btn.target = self
        }

        let controller = NSHostingController(rootView: PopoverView().environmentObject(viewModel))
        popover = NSPopover()
        popover.contentViewController = controller
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 380, height: 280)
    }

    @objc private func togglePopover() {
        guard let btn = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.refresh()
            popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY)
        }
    }
}
