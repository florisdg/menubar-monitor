import AppKit

final class MeterView: NSView {
  var state = MeterState(
    cpuUsage: 0,
    memoryUsedBytes: 0,
    totalMemoryBytes: 0,
    appMemoryBytes: 0,
    wiredMemoryBytes: 0,
    compressedMemoryBytes: 0,
    cachedMemoryBytes: 0,
    swapUsedBytes: 0,
    memoryPressure: .normal
  ) {
    didSet { needsDisplay = true }
  }

  /// Lets clicks pass through to the status-bar button beneath the meter.
  override func hitTest(_ point: NSPoint) -> NSView? {
    nil
  }

  /// Draws two bottom-aligned, three-point-wide usage bars with a three-point gap.
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    drawBar(x: 0, fraction: state.cpuFraction, color: cpuColor)
    drawBar(x: 6, fraction: state.memoryFraction, color: memoryColor)
  }

  private var cpuColor: NSColor {
    state.isCPUCritical ? .systemRed : .labelColor
  }

  private var memoryColor: NSColor {
    switch state.memoryPressure {
    case .normal: .labelColor
    case .warning: .systemYellow
    case .critical: .systemRed
    }
  }

  /// Draws one usage bar at the supplied horizontal position.
  private func drawBar(x: CGFloat, fraction: Double, color: NSColor) {
    let height = bounds.height * CGFloat(fraction)
    guard height > 0 else { return }

    color.setFill()
    NSRect(x: x, y: 0, width: 3, height: height).fill()
  }
}
