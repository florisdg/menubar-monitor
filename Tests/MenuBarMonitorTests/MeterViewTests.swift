import AppKit
import Testing

@testable import MenuBarMonitor

@MainActor
struct MeterViewTests {
  @Test("Empty meters retain visible native pill tracks")
  func emptyMetersRetainVisibleTracks() throws {
    let view = MeterView(frame: NSRect(x: 0, y: 0, width: 11, height: 16))
    let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))

    view.cacheDisplay(in: view.bounds, to: bitmap)

    let scale = CGFloat(bitmap.pixelsWide) / view.bounds.width
    let y = Int(8 * scale)
    let cornerAlpha = try #require(bitmap.colorAt(x: 0, y: 0)).alphaComponent
    let endCenterAlpha = try #require(
      bitmap.colorAt(x: Int(2 * scale), y: Int(0.5 * scale))
    ).alphaComponent
    let topCornerAlpha = try #require(
      bitmap.colorAt(x: 0, y: bitmap.pixelsHigh - 1)
    ).alphaComponent
    let topCenterAlpha = try #require(
      bitmap.colorAt(x: Int(2 * scale), y: bitmap.pixelsHigh - Int(0.5 * scale))
    ).alphaComponent
    #expect(MeterView.trackColor == .tertiaryLabelColor)
    #expect(try #require(bitmap.colorAt(x: Int(2 * scale), y: y)).alphaComponent > 0)
    #expect(try #require(bitmap.colorAt(x: Int(9 * scale), y: y)).alphaComponent > 0)
    #expect(try #require(bitmap.colorAt(x: Int(5 * scale), y: y)).alphaComponent == 0)
    #expect(cornerAlpha < endCenterAlpha)
    #expect(topCornerAlpha < topCenterAlpha)
  }
}
