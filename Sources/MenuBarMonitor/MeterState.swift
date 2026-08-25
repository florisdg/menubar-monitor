import Foundation

enum MemoryPressure: Equatable {
  case normal
  case warning
  case critical

  /// Converts macOS memory-pressure flags into the three states shown by the meter.
  init(rawValue: Int32) {
    if rawValue & 4 != 0 {
      self = .critical
    } else if rawValue & 2 != 0 {
      self = .warning
    } else {
      self = .normal
    }
  }
}

struct MeterState: Equatable {
  let cpuUsage: Double
  let memoryUsedBytes: UInt64
  let totalMemoryBytes: UInt64
  let appMemoryBytes: UInt64
  let wiredMemoryBytes: UInt64
  let compressedMemoryBytes: UInt64
  let cachedMemoryBytes: UInt64
  let swapUsedBytes: UInt64
  let memoryPressure: MemoryPressure

  /// CPU fill, constrained to the drawable range.
  var cpuFraction: Double {
    min(max(cpuUsage / 100, 0), 1)
  }

  /// Memory fill, constrained to the drawable range.
  var memoryFraction: Double {
    guard totalMemoryBytes > 0 else { return 0 }
    return min(Double(memoryUsedBytes) / Double(totalMemoryBytes), 1)
  }

  /// Whether the CPU bar should use its critical color.
  var isCPUCritical: Bool {
    cpuUsage >= 98
  }

  /// Text displayed for CPU usage in the menu.
  var cpuDescription: String {
    String(format: "CPU: %.1f%%", cpuUsage)
  }

  /// Text displayed for memory usage in the menu.
  var memoryDescription: String {
    let percentage = String(format: "%.0f%%", memoryFraction * 100)
    return "Memory: \(percentage) — \(format(memoryUsedBytes)) / \(format(totalMemoryBytes))"
  }

  /// Detailed memory rows displayed below the overall memory value.
  var memoryDetailDescriptions: [String] {
    [
      "App Memory: \(format(appMemoryBytes))",
      "Wired Memory: \(format(wiredMemoryBytes))",
      "Compressed Memory: \(format(compressedMemoryBytes))",
      "Cached Files: \(format(cachedMemoryBytes))",
      "Swap Used: \(format(swapUsedBytes))",
    ]
  }

  /// Formats memory using the binary units macOS presents as GB.
  private func format(_ bytes: UInt64) -> String {
    guard bytes > 0 else { return "0 bytes" }

    let mebibyte = 1_048_576.0
    let gibibyte = 1_073_741_824.0
    guard Double(bytes) >= gibibyte else {
      return String(format: "%.1f MB", Double(bytes) / mebibyte)
    }
    return String(format: "%.2f GB", Double(bytes) / gibibyte)
  }
}
