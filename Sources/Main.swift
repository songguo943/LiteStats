import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create Status Bar Controller
        statusBarController = StatusBarController()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Cleanup if needed
    }
}

