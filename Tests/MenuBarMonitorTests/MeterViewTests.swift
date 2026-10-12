import AppKit
import Testing

@testable import MenuBarMonitor

@MainActor
struct MeterViewTests {
  @Test("Template tracks remain translucent in every menu bar appearance")
  func templateTrackContrast() throws {
    for name in [NSAppearance.Name.aqua, .darkAqua, .vibrantLight, .vibrantDark] {
      let appearance = try #require(NSAppearance(named: name))
      let image = MeterView.image(for: MeterView().state)
      var renderedData: Data?
      appearance.performAsCurrentDrawingAppearance {
        renderedData = image.tiffRepresentation
      }
      let data = try #require(renderedData)
      let bitmap = try #require(NSBitmapImageRep(data: data))
      let scale = CGFloat(bitmap.pixelsWide) / image.size.width
      let alpha = try #require(
        bitmap.colorAt(x: Int(2 * scale), y: Int(8 * scale))
      ).alphaComponent

      #expect(image.isTemplate)
      #expect(abs(alpha - 0.5) < 0.01)
    }
  }

  @Test("Native meter images retain their size and warning colors", arguments: [0.0, 80, 98])
  func nativeMeterImages(cpuUsage: Double) {
    for pressure in [MemoryPressure.normal, .warning, .critical, .unavailable] {
      let state = MeterState(
        cpuUsage: cpuUsage,
        memoryUsedBytes: 50,
        totalMemoryBytes: 100,
        appMemoryBytes: 0,
        wiredMemoryBytes: 0,
        compressedMemoryBytes: 0,
        cachedMemoryBytes: 0,
        swapUsedBytes: 0,
        memoryPressure: pressure
      )
      let image = MeterView.image(for: state)

      #expect(image.size == NSSize(width: 11, height: 16))
      #expect(
        image.isTemplate == (cpuUsage < 80 && (pressure == .normal || pressure == .unavailable))
      )
      #expect(image.tiffRepresentation != nil)
    }
  }

  @Test("Inactive tracks preserve native transparency in light and dark appearances")
  func tracksPreserveNativeTransparency() throws {
    for name in [NSAppearance.Name.aqua, .darkAqua] {
      let appearance = try #require(NSAppearance(named: name))
      appearance.performAsCurrentDrawingAppearance {
        #expect(MeterView.trackColor == NSColor.secondaryLabelColor)
        #expect(MeterView.trackColor.alphaComponent < NSColor.labelColor.alphaComponent)
      }
    }
  }

  @Test("CPU endpoint colors use opaque Display P3")
  func cpuEndpointColorsUseDisplayP3() {
    #expect(MeterView.cpuWarningColor.colorSpace == .displayP3)
    #expect(MeterView.cpuWarningColor.greenComponent == 0.5)
    #expect(MeterView.cpuWarningColor.alphaComponent == 1)
    #expect(MeterView.cpuCriticalColor.colorSpace == .displayP3)
    #expect(MeterView.cpuCriticalColor.greenComponent == 0.08)
    #expect(MeterView.cpuCriticalColor.alphaComponent == 1)
  }

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
      bitmap.colorAt(x: Int(2 * scale), y: Int(CGFloat(bitmap.pixelsHigh) - 0.5 * scale))
    ).alphaComponent
    #expect(try #require(bitmap.colorAt(x: Int(2 * scale), y: y)).alphaComponent > 0)
    #expect(try #require(bitmap.colorAt(x: Int(9 * scale), y: y)).alphaComponent > 0)
    #expect(try #require(bitmap.colorAt(x: Int(5 * scale), y: y)).alphaComponent == 0)
    #expect(cornerAlpha < endCenterAlpha)
    #expect(topCornerAlpha < topCenterAlpha)
  }
}
