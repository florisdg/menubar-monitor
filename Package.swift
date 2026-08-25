// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MenuBarMonitor",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "MenuBarMonitor", targets: ["MenuBarMonitor"])
  ],
  targets: [
    .executableTarget(name: "MenuBarMonitor"),
    .testTarget(name: "MenuBarMonitorTests", dependencies: ["MenuBarMonitor"]),
  ]
)
