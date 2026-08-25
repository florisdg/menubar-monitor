import AppKit

@MainActor
final class StatusBarController: NSObject {
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
    statusItem.menu = menu
  }

  /// Polls resource usage every two seconds, including while the menu is open.
  private func startPolling() {
    let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.update()
      }
    }
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
