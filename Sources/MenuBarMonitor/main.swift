import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?

  /// Creates the status item after AppKit has finished launching.
  func applicationDidFinishLaunching(_ notification: Notification) {
    statusBarController = StatusBarController()
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
