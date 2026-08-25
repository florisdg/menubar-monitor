import AppKit
import ServiceManagement
import Testing

@testable import MenuBarMonitor

@MainActor
struct StatusBarControllerTests {
  @Test("Polling remains two seconds with ten percent tolerance")
  func pollingConfiguration() {
    #expect(StatusBarController.pollingInterval == 2)
    #expect(StatusBarController.pollingTolerance == 0.2)
  }

  @Test("Menu visibility follows its delegate lifecycle")
  func menuVisibility() {
    let controller = StatusBarController()
    let menu = NSMenu()

    #expect(!controller.isMenuOpen)
    controller.menuWillOpen(menu)
    #expect(controller.isMenuOpen)
    controller.menuDidClose(menu)
    #expect(!controller.isMenuOpen)
  }

  @Test("Launch at Login checkbox reflects the system service status")
  func launchAtLoginCheckboxState() {
    #expect(StatusBarController.launchAtLoginState(for: .enabled) == .on)
    #expect(StatusBarController.launchAtLoginState(for: .notRegistered) == .off)
    #expect(StatusBarController.launchAtLoginState(for: .requiresApproval) == .off)
  }
}
