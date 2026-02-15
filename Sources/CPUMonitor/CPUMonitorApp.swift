import AppKit
import SwiftUI

// Entry point
@main
struct CPUMonitorApp {
    static func main() {
        let app = NSApplication.shared
        // Create the delegate and retain it
        let delegate = AppDelegate()
        app.delegate = delegate
        
        // Run the main event loop
        app.run()
    }
}
