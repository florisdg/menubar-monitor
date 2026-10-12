import Darwin
import Testing

@testable import MenuBarMonitor

struct ResourceSamplerTests {
  @Test("CPU usage includes user, system, and nice ticks but excludes idle ticks")
  func cpuUsage() {
    let previous = ticks(100, 200, 300, 400)
    let current = ticks(120, 210, 350, 420)
    #expect(ResourceSampler.cpuUsage(from: previous, to: current) == 50)
  }

  @Test("Every CPU counter can wrap independently", arguments: 0..<4)
  func cpuCounterRollover(counter: Int) {
    var previous = [UInt32](repeating: 100, count: 4)
    var current = [UInt32](repeating: 110, count: 4)
    previous[counter] = .max - 4
    current[counter] = 5
    #expect(
      ResourceSampler.cpuUsage(
        from: ticks(previous[0], previous[1], previous[2], previous[3]),
        to: ticks(current[0], current[1], current[2], current[3])
      ) == 75
    )
  }

  @Test("Unchanged CPU counters do not produce a new usage reading")
  func unchangedCPUCounters() {
    let value = ticks(100, 200, 300, 400)
    #expect(ResourceSampler.cpuUsage(from: value, to: value) == nil)
  }

  @Test("CPU deltas are widened before their sum can overflow")
  func largeCPUDeltas() {
    #expect(
      ResourceSampler.cpuUsage(from: ticks(0, 0, 0, 0), to: ticks(.max, .max, .max, .max)) == 75)
  }

  @Test("VM page counts produce the expected memory breakdown", arguments: [UInt64(4096), 16384])
  func memoryBreakdown(pageSize: UInt64) {
    var info = vm_statistics64_data_t()
    info.internal_page_count = 60
    info.purgeable_count = 10
    info.wire_count = 15
    info.compressor_page_count = 5
    info.external_page_count = 10
    info.free_count = 20
    let stats = ResourceSampler.memoryStats(
      from: info, totalBytes: 100 * pageSize, pageSize: pageSize)
    #expect(stats.used == 60 * pageSize)
    #expect(stats.total == 100 * pageSize)
    #expect(stats.app == 50 * pageSize)
    #expect(stats.wired == 15 * pageSize)
    #expect(stats.compressed == 5 * pageSize)
    #expect(stats.cached == 20 * pageSize)
  }

  @Test("Transient VM counters cannot underflow used or app memory")
  func memoryCountersExceedTotals() {
    var info = vm_statistics64_data_t()
    info.internal_page_count = 1
    info.purgeable_count = 2
    info.free_count = 10
    let stats = ResourceSampler.memoryStats(from: info, totalBytes: 4096, pageSize: 4096)
    #expect(stats.used == 0)
    #expect(stats.app == 0)
  }

  @Test("Pressure read failures cannot masquerade as a healthy reading")
  func pressureReadFailure() {
    let pressure = ResourceSampler.readMemoryPressure { value, _ in
      value = 1
      return -1
    }
    #expect(pressure == .unavailable)
  }

  @Test("Successful system pressure readings are parsed", arguments: [Int32(1), 2, 4])
  func pressureReadSuccess(rawValue: Int32) {
    let pressure = ResourceSampler.readMemoryPressure { value, size in
      #expect(size == MemoryLayout<Int32>.size)
      value = rawValue
      return 0
    }
    #expect(pressure == MemoryPressure(rawValue: rawValue))
  }

  /// Builds a native CPU reading in Mach's user, system, idle, and nice order.
  private func ticks(_ user: UInt32, _ system: UInt32, _ idle: UInt32, _ nice: UInt32)
    -> host_cpu_load_info_data_t
  {
    var info = host_cpu_load_info_data_t()
    info.cpu_ticks = (user, system, idle, nice)
    return info
  }
}
