import AppKit

final class MeterView: NSView {
  /// Native adaptive fill used for the unfilled portion of each bar.
  static let trackColor = NSColor.tertiaryLabelColor

  /// Wide-gamut endpoint for elevated CPU usage.
  static let cpuWarningColor = NSColor(
    displayP3Red: 1,
    green: 0.5,
    blue: 0,
    alpha: 1
  )

  /// Wide-gamut endpoint for critical CPU usage.
  static let cpuCriticalColor = NSColor(
    displayP3Red: 1,
    green: 0.08,
    blue: 0.05,
    alpha: 1
  )

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

  /// Draws two bottom-aligned, four-point-wide usage bars with a three-point gap.
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    drawBar(x: 0, fraction: state.cpuFraction, color: cpuColor)
    drawBar(x: 7, fraction: state.memoryFraction, color: memoryColor)
  }

  private var cpuColor: NSColor {
    guard !state.isCPUCritical else { return Self.cpuCriticalColor }
    return state.isCPUWarning ? Self.cpuWarningColor : .labelColor
  }

  private var memoryColor: NSColor {
    switch state.memoryPressure {
    case .normal: .labelColor
    case .warning: .systemYellow
    case .critical: .systemRed
    }
  }

  /// Draws one usage bar and its full-height track at the supplied horizontal position.
  private func drawBar(x: CGFloat, fraction: Double, color: NSColor) {
    let rect = NSRect(x: x, y: 0, width: 4, height: bounds.height)
    let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)

    Self.trackColor.setFill()
    path.fill()

    let height = bounds.height * CGFloat(fraction)
    guard height > 0 else { return }

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    color.setFill()
    NSRect(x: x, y: 0, width: 4, height: height).fill()
    NSGraphicsContext.restoreGraphicsState()
  }
}
