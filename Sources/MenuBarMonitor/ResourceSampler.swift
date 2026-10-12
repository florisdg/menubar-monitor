import Darwin
import Foundation

/// Samples aggregate macOS resource counters for the menu-bar meters.
final class ResourceSampler {
  /// Byte counts derived from the kernel's VM page statistics.
  struct MemoryStats {
    let used: UInt64
    let total: UInt64
    let app: UInt64
    let wired: UInt64
    let compressed: UInt64
    let cached: UInt64
  }

  private let totalMemoryBytes = ProcessInfo.processInfo.physicalMemory
  private let pageSizeBytes = UInt64(getpagesize())
  private var previousCPUTicks: host_cpu_load_info_data_t?
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
      memoryPressure: Self.readMemoryPressure { rawValue, size in
        sysctlbyname("kern.memorystatus_vm_pressure_level", &rawValue, &size, nil, 0)
      }
    )
  }

  /// Calculates CPU use from the change in host CPU ticks since the previous sample.
  private func readCPUUsage() -> Double {
    guard let current = readCPUTicks() else { return lastCPUUsage }
    defer { previousCPUTicks = current }

    guard let previousCPUTicks else { return lastCPUUsage }

    guard let usage = Self.cpuUsage(from: previousCPUTicks, to: current) else {
      return lastCPUUsage
    }
    lastCPUUsage = usage
    return lastCPUUsage
  }

  /// Calculates deltas before widening so each 32-bit counter can wrap independently.
  static func cpuUsage(
    from previous: host_cpu_load_info_data_t,
    to current: host_cpu_load_info_data_t
  ) -> Double? {
    let user = UInt64(current.cpu_ticks.0 &- previous.cpu_ticks.0)
    let system = UInt64(current.cpu_ticks.1 &- previous.cpu_ticks.1)
    let idle = UInt64(current.cpu_ticks.2 &- previous.cpu_ticks.2)
    let nice = UInt64(current.cpu_ticks.3 &- previous.cpu_ticks.3)
    let busy = user + system + nice
    let total = busy + idle
    guard total > 0 else { return nil }
    return Double(busy) / Double(total) * 100
  }

  /// Reads cumulative user, system, nice, and idle ticks from the Mach host API.
  private func readCPUTicks() -> host_cpu_load_info_data_t? {
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

    return info
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

    return Self.memoryStats(from: info, totalBytes: totalMemoryBytes, pageSize: pageSizeBytes)
  }

  /// Converts VM page counters to bytes without counting purgeable pages as app memory.
  static func memoryStats(
    from info: vm_statistics64_data_t,
    totalBytes: UInt64,
    pageSize: UInt64
  ) -> MemoryStats {
    let internalPages = UInt64(info.internal_page_count)
    let purgeablePages = UInt64(info.purgeable_count)
    let appPages = internalPages > purgeablePages ? internalPages - purgeablePages : 0
    let app = appPages * pageSize
    let wired = UInt64(info.wire_count) * pageSize
    let compressed = UInt64(info.compressor_page_count) * pageSize
    let cached = (UInt64(info.external_page_count) + purgeablePages) * pageSize
    let free = UInt64(info.free_count) * pageSize

    return MemoryStats(
      used: totalBytes - min(free + cached, totalBytes),
      total: totalBytes,
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

  /// Reads pressure through the supplied system call, preserving an unavailable reading.
  static func readMemoryPressure(using read: (inout Int32, inout Int) -> Int32) -> MemoryPressure {
    var rawValue: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard read(&rawValue, &size) == 0 else { return .unavailable }
    return MemoryPressure(rawValue: rawValue)
  }
}
