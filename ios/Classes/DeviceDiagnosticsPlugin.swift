
import Flutter
import UIKit
import Foundation
import Network
import Darwin

public class DeviceDiagnosticsPlugin: NSObject, FlutterPlugin {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "device_diagnostics.network")
    private let stateLock = NSLock()

    private var networkType = "unknown"
    private var previousCpuSeconds: Double?
    private var previousUptime: Double?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "device_diagnostics/native",
            binaryMessenger: registrar.messenger()
        )

        let instance = DeviceDiagnosticsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    override init() {
        super.init()

        monitor.pathUpdateHandler = { [weak self] path in
            let type: String

            if path.status != .satisfied {
                type = "offline"
            } else if path.usesInterfaceType(.wifi) {
                type = "wifi"
            } else if path.usesInterfaceType(.cellular) {
                type = "cellular"
            } else if path.usesInterfaceType(.wiredEthernet) {
                type = "ethernet"
            } else {
                type = "other"
            }

            self?.stateLock.lock()
            self?.networkType = type
            self?.stateLock.unlock()
        }

        monitor.start(queue: queue)
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard call.method == "sampleMetrics" else {
            result(FlutterMethodNotImplemented)
            return
        }

        result(collectMetrics())
    }

    private func collectMetrics() -> [String: Any] {
        var out: [String: Any] = [
            "model": Self.machineModel(),
            "manufacturer": "Apple",
            "osVersion": "iOS \(UIDevice.current.systemVersion)",
            "architecture": "unavailable",
            "soc": NSNull(),
            "hardwareDecoder": NSNull(),
            "rxBytes": NSNull(),
            "txBytes": NSNull()
        ]

        stateLock.lock()
        let currentNetworkType = networkType
        stateLock.unlock()
        out["networkType"] = currentNetworkType

        // Process resident memory in bytes.
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size /
            MemoryLayout<integer_t>.size
        )

        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(
                to: integer_t.self,
                capacity: Int(count)
            ) { reboundPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    reboundPointer,
                    &count
                )
            }
        }

        if status == KERN_SUCCESS {
            out["memoryBytes"] = Int(info.resident_size)
        } else {
            out["memoryBytes"] = NSNull()
        }

        // Process CPU time: user + system time for this process.
        // systemUptime is monotonic and is measured in seconds.
        var usage = rusage()
        let usageStatus = getrusage(RUSAGE_SELF, &usage)
        let uptime = ProcessInfo.processInfo.systemUptime

        if usageStatus == 0 {
            let userSeconds =
                Double(usage.ru_utime.tv_sec) +
                Double(usage.ru_utime.tv_usec) / 1_000_000.0

            let systemSeconds =
                Double(usage.ru_stime.tv_sec) +
                Double(usage.ru_stime.tv_usec) / 1_000_000.0

            let cpuSeconds = userSeconds + systemSeconds

            if let previousCpu = previousCpuSeconds,
               let previousTime = previousUptime {
                let cpuDelta = cpuSeconds - previousCpu
                let elapsedDelta = uptime - previousTime

                if cpuDelta >= 0, elapsedDelta > 0 {
                    let percent = (cpuDelta / elapsedDelta) * 100.0
                    out["cpuPercent"] = min(max(percent, 0.0), 100.0)
                } else {
                    out["cpuPercent"] = NSNull()
                }
            } else {
                out["cpuPercent"] = NSNull()
            }

            previousCpuSeconds = cpuSeconds
            previousUptime = uptime
        } else {
            out["cpuPercent"] = NSNull()
        }

        if #available(iOS 11.0, *) {
            switch ProcessInfo.processInfo.thermalState {
            case .nominal:
                out["thermalState"] = "nominal"
            case .fair:
                out["thermalState"] = "fair"
            case .serious:
                out["thermalState"] = "serious"
            case .critical:
                out["thermalState"] = "critical"
            @unknown default:
                out["thermalState"] = "unknown"
            }
        } else {
            out["thermalState"] = NSNull()
        }

        return out
    }

    private static func machineModel() -> String {
        var size = 0
        guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0,
              size > 0 else {
            return "unknown"
        }

        var machine = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.machine", &machine, &size, nil, 0) == 0 else {
            return "unknown"
        }

        return String(cString: machine)
    }

    deinit {
        monitor.cancel()
    }
}
