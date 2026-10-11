import Flutter
import UIKit
import Foundation
import Network
import Darwin

public class DeviceDiagnosticsPlugin: NSObject, FlutterPlugin {
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "device_diagnostics.network")
  private var networkType = "unknown"
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "device_diagnostics/native", binaryMessenger: registrar.messenger())
    let instance = DeviceDiagnosticsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  override init() {
    super.init()
    monitor.pathUpdateHandler = { [weak self] path in
      if path.status != .satisfied { self?.networkType = "offline" }
      else if path.usesInterfaceType(.wifi) { self?.networkType = "wifi" }
      else if path.usesInterfaceType(.cellular) { self?.networkType = "cellular" }
      else if path.usesInterfaceType(.wiredEthernet) { self?.networkType = "ethernet" }
      else { self?.networkType = "other" }
    }
    monitor.start(queue: queue)
  }
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "sampleMetrics" else { result(FlutterMethodNotImplemented); return }
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    let kr = withUnsafeMutablePointer(to: &info) { ptr in
      ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count) }
    }
    var out: [String: Any] = ["networkType": networkType, "model": Self.machineModel(), "manufacturer": "Apple", "osVersion": "iOS \(UIDevice.current.systemVersion)", "architecture": "unavailable", "soc": NSNull(), "hardwareDecoder": NSNull(), "cpuPercent": NSNull(), "rxBytes": NSNull(), "txBytes": NSNull()]
    if kr == KERN_SUCCESS { out["memoryBytes"] = Int(info.resident_size) } else { out["memoryBytes"] = NSNull() }
    if #available(iOS 11.0, *) {
      switch ProcessInfo.processInfo.thermalState {
      case .nominal: out["thermalState"] = "nominal"
      case .fair: out["thermalState"] = "fair"
      case .serious: out["thermalState"] = "serious"
      case .critical: out["thermalState"] = "critical"
      @unknown default: out["thermalState"] = "unknown"
      }
    } else { out["thermalState"] = NSNull() }
    result(out)
  }
  private static func machineModel() -> String {
    var size = 0; sysctlbyname("hw.machine", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.machine", &machine, &size, nil, 0)
    return String(cString: machine)
  }
}
