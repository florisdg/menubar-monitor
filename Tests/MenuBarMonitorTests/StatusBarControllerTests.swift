import AppKit
import ServiceManagement
import Testing

@testable import MenuBarMonitor

@MainActor
struct StatusBarControllerTests {
  @Test("Launch at Login checkbox reflects the system service status")
  func launchAtLoginCheckboxState() {
    #expect(StatusBarController.launchAtLoginState(for: .enabled) == .on)
    #expect(StatusBarController.launchAtLoginState(for: .notRegistered) == .off)
    #expect(StatusBarController.launchAtLoginState(for: .requiresApproval) == .off)
  }
}
