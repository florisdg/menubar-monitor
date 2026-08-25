import Darwin
import Foundation

final class ResourceSampler {
  private struct CPUTicks {
    let busy: UInt64
    let total: UInt64
  }

  private struct MemoryStats {
    let used: UInt64
    let total: UInt64
    let app: UInt64
    let wired: UInt64
    let compressed: UInt64
    let cached: UInt64
  }

  private let totalMemoryBytes = ProcessInfo.processInfo.physicalMemory
  private let pageSizeBytes = UInt64(getpagesize())
  private var previousCPUTicks: CPUTicks?
  private var lastCPUUsage = 0.0

  init() {
    previousCPUTicks = readCPUTicks()
  }

  /// Samples aggregate CPU load, physical memory use, and current memory pressure.
  func sample() -> MeterState {
    let memory = readMemoryUsage()

    return MeterState(
      cpuUsage: readCPUUsage(),
      memoryUsedBytes: memory.used,
      totalMemoryBytes: memory.total,
      appMemoryBytes: memory.app,
      wiredMemoryBytes: memory.wired,
      compressedMemoryBytes: memory.compressed,
      cachedMemoryBytes: memory.cached,
      swapUsedBytes: readSwapUsed(),
      memoryPressure: readMemoryPressure()
    )
  }

  /// Calculates CPU use from the change in host CPU ticks since the previous sample.
  private func readCPUUsage() -> Double {
    guard let current = readCPUTicks() else { return lastCPUUsage }
    defer { previousCPUTicks = current }

    guard let previousCPUTicks else { return lastCPUUsage }

    let busyDelta = current.busy - previousCPUTicks.busy
    let totalDelta = current.total - previousCPUTicks.total
    guard totalDelta > 0 else { return lastCPUUsage }

    lastCPUUsage = Double(busyDelta) / Double(totalDelta) * 100
    return lastCPUUsage
  }

  /// Reads cumulative user, system, nice, and idle ticks from the Mach host API.
  private func readCPUTicks() -> CPUTicks? {
    var info = host_cpu_load_info_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
    )
    let result = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
      }
    }

    guard result == KERN_SUCCESS else { return nil }

    let user = UInt64(info.cpu_ticks.0)
    let system = UInt64(info.cpu_ticks.1)
    let idle = UInt64(info.cpu_ticks.2)
    let nice = UInt64(info.cpu_ticks.3)
    let busy = user + system + nice
    return CPUTicks(busy: busy, total: busy + idle)
  }

  /// Reads the Mach VM counters used for Activity Monitor's memory breakdown.
  private func readMemoryUsage() -> MemoryStats {
    var info = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
    )
    let result = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }

    guard result == KERN_SUCCESS else { return emptyMemoryStats(total: totalMemoryBytes) }

    let internalPages = UInt64(info.internal_page_count)
    let purgeablePages = UInt64(info.purgeable_count)
    let appPages = internalPages > purgeablePages ? internalPages - purgeablePages : 0
    let app = appPages * pageSizeBytes
    let wired = UInt64(info.wire_count) * pageSizeBytes
    let compressed = UInt64(info.compressor_page_count) * pageSizeBytes
    let cached = (UInt64(info.external_page_count) + purgeablePages) * pageSizeBytes
    let free = UInt64(info.free_count) * pageSizeBytes

    return MemoryStats(
      used: totalMemoryBytes - min(free + cached, totalMemoryBytes),
      total: totalMemoryBytes,
      app: app,
      wired: wired,
      compressed: compressed,
      cached: cached
    )
  }

  /// Creates a zeroed reading when Mach host statistics are unavailable.
  private func emptyMemoryStats(total: UInt64) -> MemoryStats {
    MemoryStats(used: 0, total: total, app: 0, wired: 0, compressed: 0, cached: 0)
  }

  /// Reads the amount of swap space currently occupied by memory pages.
  private func readSwapUsed() -> UInt64 {
    var usage = xsw_usage()
    var size = MemoryLayout<xsw_usage>.size
    guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else { return 0 }
    return usage.xsu_used
  }

  /// Reads macOS's current normal, warning, or critical memory-pressure level.
  private func readMemoryPressure() -> MemoryPressure {
    var rawValue: Int32 = 1
    var size = MemoryLayout<Int32>.size
    sysctlbyname("kern.memorystatus_vm_pressure_level", &rawValue, &size, nil, 0)
    return MemoryPressure(rawValue: rawValue)
  }
}
