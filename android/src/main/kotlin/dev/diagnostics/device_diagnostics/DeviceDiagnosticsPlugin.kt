
package dev.diagnostics.device_diagnostics

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.os.SystemClock
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceDiagnosticsPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private var previousCpuTimeMs: Long? = null
    private var previousElapsedTimeMs: Long? = null

    override fun onAttachedToEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        context = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger,
            "device_diagnostics/native"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (call.method != "sampleMetrics") {
            result.notImplemented()
            return
        }

        try {
            result.success(collectMetrics())
        } catch (exception: Exception) {
            result.error(
                "METRICS_FAILED",
                exception.message ?: "Unable to collect diagnostic metrics",
                null
            )
        }
    }

    private fun collectMetrics(): Map<String, Any?> {
        val out = mutableMapOf<String, Any?>()

        // Process memory estimate (PSS), converted from KiB to bytes.
        out["memoryBytes"] = Debug.getPss().toLong() * 1024L

        // Process CPU time and monotonic elapsed time are both measured in ms.
        val cpuTimeMs = android.os.Process.getElapsedCpuTime()
        val elapsedTimeMs = SystemClock.elapsedRealtime()

        val previousCpu = previousCpuTimeMs
        val previousElapsed = previousElapsedTimeMs

        if (previousCpu != null && previousElapsed != null) {
            val cpuDelta = cpuTimeMs - previousCpu
            val elapsedDelta = elapsedTimeMs - previousElapsed

            if (cpuDelta >= 0L && elapsedDelta > 0L) {
                // Percentage relative to one CPU core; capped at 100%.
                out["cpuPercent"] =
                    ((cpuDelta.toDouble() / elapsedDelta.toDouble()) * 100.0)
                        .coerceIn(0.0, 100.0)
            }
        }

        previousCpuTimeMs = cpuTimeMs
        previousElapsedTimeMs = elapsedTimeMs

        // App UID network counters; they may include other same-UID traffic.
        val uid = android.os.Process.myUid()
        val rx = TrafficStats.getUidRxBytes(uid)
        val tx = TrafficStats.getUidTxBytes(uid)

        if (rx != TrafficStats.UNSUPPORTED.toLong() && rx >= 0L) {
            out["rxBytes"] = rx
        }
        if (tx != TrafficStats.UNSUPPORTED.toLong() && tx >= 0L) {
            out["txBytes"] = tx
        }

        out["networkType"] = getNetworkType()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val powerManager =
                context.getSystemService(Context.POWER_SERVICE) as PowerManager

            out["thermalState"] = when (powerManager.currentThermalStatus) {
                PowerManager.THERMAL_STATUS_NONE -> "none"
                PowerManager.THERMAL_STATUS_LIGHT -> "light"
                PowerManager.THERMAL_STATUS_MODERATE -> "moderate"
                PowerManager.THERMAL_STATUS_SEVERE -> "severe"
                PowerManager.THERMAL_STATUS_CRITICAL -> "critical"
                PowerManager.THERMAL_STATUS_EMERGENCY -> "emergency"
                PowerManager.THERMAL_STATUS_SHUTDOWN -> "shutdown"
                else -> "unknown"
            }
        }

        out["model"] = Build.MODEL
        out["manufacturer"] = Build.MANUFACTURER
        out["osVersion"] =
            "Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})"
        out["soc"] =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Build.SOC_MODEL
            } else {
                null
            }
        out["architecture"] = Build.SUPPORTED_ABIS.firstOrNull()
        out["hardwareDecoder"] = null

        return out
    }

    private fun getNetworkType(): String {
        val manager = context.getSystemService(
            Context.CONNECTIVITY_SERVICE
        ) as ConnectivityManager

        val network = manager.activeNetwork ?: return "offline"
        val capabilities = manager.getNetworkCapabilities(network)
            ?: return "unknown"

        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ->
                "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ->
                "cellular"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) ->
                "ethernet"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) ->
                "vpn"
            else -> "other"
        }
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)

        // Reset sampling baselines for the next engine attachment
        previousCpuTimeMs = null
        previousElapsedTimeMs = null
    }
}
