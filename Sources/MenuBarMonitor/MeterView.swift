import AppKit

final class MeterView: NSView {
  /// Native secondary fill preserves adaptive transparency for inactive tracks.
  static let trackColor = NSColor.secondaryLabelColor

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

  /// Uses native status-button styling for normal usage and retains warning colors.
  static func image(for state: MeterState) -> NSImage {
    let view = MeterView(frame: NSRect(x: 0, y: 0, width: 11, height: 16))
    view.state = state
    let image = NSImage(size: NSSize(width: 11, height: 16), flipped: false) { rect in
      MainActor.assumeIsolated {
        view.draw(rect)
        return true
      }
    }
    image.isTemplate = view.usesTemplateColors
    return image
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

  private var usesTemplateColors: Bool {
    !state.isCPUWarning && (state.memoryPressure == .normal || state.memoryPressure == .unavailable)
  }

  private var memoryColor: NSColor {
    switch state.memoryPressure {
    case .normal, .unavailable: .labelColor
    case .warning: .systemYellow
    case .critical: .systemRed
    }
  }

  /// Draws one usage bar and its full-height track at the supplied horizontal position.
  private func drawBar(x: CGFloat, fraction: Double, color: NSColor) {
    let rect = NSRect(x: x, y: 0, width: 4, height: bounds.height)
    let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)

    // Templates use alpha, not RGB shading; vibrant semantic colors can be opaque.
    let trackColor = usesTemplateColors ? NSColor.black.withAlphaComponent(0.5) : Self.trackColor
    trackColor.setFill()
    path.fill()

    let height = bounds.height * CGFloat(fraction)
    guard height > 0 else { return }

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    (usesTemplateColors ? NSColor.black : color).setFill()
    NSRect(x: x, y: 0, width: 4, height: height).fill()
    NSGraphicsContext.restoreGraphicsState()
  }
}
