import AppKit
import ServiceManagement

@MainActor
final class StatusBarController: NSObject {
  /// Sampling cadence for the always-visible meters.
  static let pollingInterval = 2.0

  /// Lets macOS coalesce meter updates with other processor wake-ups.
  static let pollingTolerance = pollingInterval / 10

  private let sampler = ResourceSampler()
  private let statusItem = NSStatusBar.system.statusItem(withLength: 17)
  private let meterView = MeterView()
  private let cpuMenuItem = NSMenuItem(title: "CPU: 0.0%", action: nil, keyEquivalent: "")
  private let memoryMenuItem = NSMenuItem(
    title: "Memory: 0.0 GB / 0.0 GB",
    action: nil,
    keyEquivalent: ""
  )
  private let memoryDetailMenuItems = (0..<5).map { _ in
    NSMenuItem(title: "", action: nil, keyEquivalent: "")
  }
  private let launchAtLoginItem = NSMenuItem(
    title: "Launch at Login",
    action: nil,
    keyEquivalent: ""
  )
  private var timer: Timer?

  override init() {
    super.init()
    configureStatusItem()
    update()
    startPolling()
  }

  /// Installs the meter view and its detail-and-command menu in the system status bar.
  private func configureStatusItem() {
    guard let button = statusItem.button else { return }

    meterView.translatesAutoresizingMaskIntoConstraints = false
    button.addSubview(meterView)
    NSLayoutConstraint.activate([
      meterView.widthAnchor.constraint(equalToConstant: 11),
      meterView.heightAnchor.constraint(equalToConstant: 16),
      meterView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
      meterView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
    ])

    cpuMenuItem.isEnabled = false
    memoryMenuItem.isEnabled = false
    for item in memoryDetailMenuItems {
      item.isEnabled = false
    }

    let menu = NSMenu()
    menu.addItem(cpuMenuItem)
    menu.addItem(memoryMenuItem)
    menu.addItem(.separator())
    memoryDetailMenuItems.forEach(menu.addItem)
    menu.addItem(.separator())

    launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
    launchAtLoginItem.target = self
    menu.addItem(launchAtLoginItem)

    let openActivityMonitorItem = NSMenuItem(
      title: "Open Activity Monitor",
      action: #selector(openActivityMonitor),
      keyEquivalent: ""
    )
    openActivityMonitorItem.target = self
    menu.addItem(openActivityMonitorItem)

    let quitItem = NSMenuItem(
      title: "Quit Menu Bar Monitor",
      action: #selector(quit),
      keyEquivalent: "q"
    )
    quitItem.target = self
    menu.addItem(quitItem)
    menu.delegate = self
    statusItem.menu = menu
  }

  /// Maps the system login-item status to the menu item's checkbox state.
  static func launchAtLoginState(for status: SMAppService.Status) -> NSControl.StateValue {
    status == .enabled ? .on : .off
  }

  /// Refreshes the checkbox from macOS's current login-item status.
  private func updateLaunchAtLoginItem() {
    launchAtLoginItem.state = Self.launchAtLoginState(for: SMAppService.mainApp.status)
  }

  /// Registers or unregisters the app as a macOS login item.
  @objc private func toggleLaunchAtLogin() {
    let service = SMAppService.mainApp

    do {
      switch service.status {
      case .enabled:
        try service.unregister()
      case .requiresApproval:
        SMAppService.openSystemSettingsLoginItems()
      default:
        try service.register()
      }
    } catch {
      updateLaunchAtLoginItem()
      guard service.status != .requiresApproval else {
        SMAppService.openSystemSettingsLoginItems()
        return
      }
      NSAlert(error: error).runModal()
      return
    }

    updateLaunchAtLoginItem()
    if service.status == .requiresApproval {
      SMAppService.openSystemSettingsLoginItems()
    }
  }

  /// Polls resource usage every two seconds, including while the menu is open.
  private func startPolling() {
    let timer = Timer(timeInterval: Self.pollingInterval, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.update()
      }
    }
    timer.tolerance = Self.pollingTolerance
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  /// Refreshes both bars and their corresponding detail rows.
  private func update() {
    let state = sampler.sample()
    meterView.state = state
    cpuMenuItem.title = state.cpuDescription
    memoryMenuItem.title = state.memoryDescription
    for (item, description) in zip(memoryDetailMenuItems, state.memoryDetailDescriptions) {
      item.title = description
    }
  }

  /// Opens macOS's Activity Monitor application.
  @objc private func openActivityMonitor() {
    guard
      let url = NSWorkspace.shared.urlForApplication(
        withBundleIdentifier: "com.apple.ActivityMonitor"
      )
    else { return }

    NSWorkspace.shared.openApplication(at: url, configuration: .init())
  }

  /// Terminates the background application.
  @objc private func quit() {
    NSApplication.shared.terminate(nil)
  }
}

extension StatusBarController: NSMenuDelegate {
  /// Refreshes external Login Items changes before presenting the menu.
  func menuWillOpen(_ menu: NSMenu) {
    updateLaunchAtLoginItem()
  }
}
