import Testing

@testable import MenuBarMonitor

struct MeterStateTests {
  @Test("CPU fill is clamped to the drawable range")
  func cpuFillIsClamped() {
    #expect(makeState(cpuUsage: -1).cpuFraction == 0)
    #expect(makeState(cpuUsage: 42).cpuFraction == 0.42)
    #expect(makeState(cpuUsage: 101).cpuFraction == 1)
  }

  @Test("CPU turns critical at exactly 98 percent")
  func cpuCriticalThreshold() {
    #expect(!makeState(cpuUsage: 97.9).isCPUCritical)
    #expect(makeState(cpuUsage: 98).isCPUCritical)
  }

  @Test("Memory fill and labels use the sampled byte counts")
  func memoryPresentation() {
    let state = MeterState(
      cpuUsage: 12.34,
      memoryUsedBytes: 8 * 1_073_741_824,
      totalMemoryBytes: 16 * 1_073_741_824,
      appMemoryBytes: 4 * 1_073_741_824,
      wiredMemoryBytes: 2 * 1_073_741_824,
      compressedMemoryBytes: 2 * 1_073_741_824,
      cachedMemoryBytes: 6 * 1_073_741_824,
      swapUsedBytes: 1 * 1_073_741_824,
      memoryPressure: .normal
    )

    #expect(state.memoryFraction == 0.5)
    #expect(state.cpuDescription == "CPU: 12.3%")
    #expect(state.memoryDescription == "Memory: 50% — 8.00 GB / 16.00 GB")
    #expect(
      state.memoryDetailDescriptions == [
        "App Memory: 4.00 GB",
        "Wired Memory: 2.00 GB",
        "Compressed Memory: 2.00 GB",
        "Cached Files: 6.00 GB",
        "Swap Used: 1.00 GB",
      ]
    )
  }

  @Test("Memory formatting follows Activity Monitor units")
  func activityMonitorMemoryFormatting() {
    let state = MeterState(
      cpuUsage: 0,
      memoryUsedBytes: 40 * 1_073_741_824,
      totalMemoryBytes: 48 * 1_073_741_824,
      appMemoryBytes: 512 * 1_048_576,
      wiredMemoryBytes: 0,
      compressedMemoryBytes: 0,
      cachedMemoryBytes: 0,
      swapUsedBytes: 0,
      memoryPressure: .normal
    )

    #expect(state.memoryDescription == "Memory: 83% — 40.00 GB / 48.00 GB")
    #expect(state.memoryDetailDescriptions[0] == "App Memory: 512.0 MB")
    #expect(state.memoryDetailDescriptions[4] == "Swap Used: 0 bytes")
  }

  @Test("Memory pressure flags map to normal, warning, and critical")
  func memoryPressureMapping() {
    #expect(MemoryPressure(rawValue: 1) == .normal)
    #expect(MemoryPressure(rawValue: 2) == .warning)
    #expect(MemoryPressure(rawValue: 4) == .critical)
  }

  /// Creates a minimal state for CPU-specific assertions.
  private func makeState(cpuUsage: Double) -> MeterState {
    MeterState(
      cpuUsage: cpuUsage,
      memoryUsedBytes: 0,
      totalMemoryBytes: 1,
      appMemoryBytes: 0,
      wiredMemoryBytes: 0,
      compressedMemoryBytes: 0,
      cachedMemoryBytes: 0,
      swapUsedBytes: 0,
      memoryPressure: .normal
    )
  }
}
