import AppKit
import Testing

@testable import MenuBarMonitor

@MainActor
struct MeterViewTests {
  @Test("Empty meters retain visible native tracks")
  func emptyMetersRetainVisibleTracks() throws {
    let view = MeterView(frame: NSRect(x: 0, y: 0, width: 9, height: 16))
    let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))

    view.cacheDisplay(in: view.bounds, to: bitmap)

    let scale = CGFloat(bitmap.pixelsWide) / view.bounds.width
    let y = Int(8 * scale)
    #expect(MeterView.trackColor == .tertiaryLabelColor)
    #expect(try #require(bitmap.colorAt(x: Int(1 * scale), y: y)).alphaComponent > 0)
    #expect(try #require(bitmap.colorAt(x: Int(7 * scale), y: y)).alphaComponent > 0)
    #expect(try #require(bitmap.colorAt(x: Int(4 * scale), y: y)).alphaComponent == 0)
  }
}
