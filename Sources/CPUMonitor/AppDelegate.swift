import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    // Timer to update status bar title if needed
    // The view model handles the data fetching
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Using a system symbol for the icon
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "CPU Monitor")
            button.action = #selector(togglePopover(_:))
        }
        
        // Create the SwiftUI view for the popover
        let contentView = PopoverView()
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 400)
        popover.behavior = .transient
        // Wrap the SwiftUI view in an NSHostingController
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Force window to front
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
