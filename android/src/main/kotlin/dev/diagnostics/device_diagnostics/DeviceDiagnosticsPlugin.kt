package dev.diagnostics.device_diagnostics

import android.app.ActivityManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.net.TrafficStats
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.RandomAccessFile

class DeviceDiagnosticsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var previousCpuMs: Long? = null
    private var previousWallMs: Long? = null
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "device_diagnostics/native")
        channel.setMethodCallHandler(this)
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "sampleMetrics") { result.notImplemented(); return }
        try {
            val out = HashMap<String, Any?>()
            out["memoryBytes"] = Debug.getPss().toLong() * 1024L
            val cpu = readCpuMillis(); val wall = System.currentTimeMillis()
            if (cpu != null && previousCpuMs != null && previousWallMs != null) {
                val deltaWall = wall - previousWallMs!!; val deltaCpu = cpu - previousCpuMs!!
                if (deltaWall > 0) out["cpuPercent"] = ((deltaCpu.toDouble() / deltaWall.toDouble()) * 100.0).coerceIn(0.0, 100.0)
            }
            previousCpuMs = cpu; previousWallMs = wall
            val rx = TrafficStats.getUidRxBytes(android.os.Process.myUid()); val tx = TrafficStats.getUidTxBytes(android.os.Process.myUid())
            if (rx != TrafficStats.UNSUPPORTED.toLong() && rx >= 0) out["rxBytes"] = rx
            if (tx != TrafficStats.UNSUPPORTED.toLong() && tx >= 0) out["txBytes"] = tx
            out["networkType"] = networkType()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                out["thermalState"] = when (pm.currentThermalStatus) { 0 -> "none"; 1 -> "light"; 2 -> "moderate"; 3 -> "severe"; 4 -> "critical"; 5 -> "emergency"; 6 -> "shutdown"; else -> "unknown" }
            }
            out["model"] = Build.MODEL; out["manufacturer"] = Build.MANUFACTURER; out["osVersion"] = "Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})"; out["soc"] = if (Build.VERSION.SDK_INT >= 31) Build.SOC_MODEL else null; out["architecture"] = Build.SUPPORTED_ABIS.firstOrNull()
            out["hardwareDecoder"] = null // Android does not expose one device-wide active decoder.
            result.success(out)
        } catch (e: Exception) { result.error("METRICS_FAILED", e.message, null) }
    }
    private fun networkType(): String {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return "offline"
        val caps = cm.getNetworkCapabilities(network) ?: return "unknown"
        return when { caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"; caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"; caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"; caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"; else -> "other" }
    }
    private fun readCpuMillis(): Long? = try {
        val stat = RandomAccessFile("/proc/self/stat", "r").use { it.readLine() }
        val close = stat.lastIndexOf(')'); val fields = stat.substring(close + 2).split(Regex("\s+"))
        val ticks = fields[11].toLong() + fields[12].toLong()
        ticks * 1000L / 100L // Linux USER_HZ is commonly 100; this is an estimate.
    } catch (_: Exception) { null }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) { channel.setMethodCallHandler(null) }
}
