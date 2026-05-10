package net.aden.data.bridge

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.TrafficStats
import android.net.VpnService
import android.os.Build
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import net.aden.data.ai.NetworkClassifierV2
import net.aden.data.vpn.AdenVpnService
import net.aden.data.vpn.AiState
import net.aden.data.receiver.ConnectivityWatcher
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * VpnBridge — MethodChannel + EventChannel handler.
 * Channel name: "com.aden.data/vpn"
 * EventChannel name: "com.aden.data/vpn_stats"
 */
class VpnBridge(private val context: Context) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "VpnBridge"
        const val METHOD_CHANNEL = "com.aden.data/vpn"
        const val EVENT_CHANNEL = "com.aden.data/vpn_stats"
        private const val VPN_REQUEST_CODE = 100
    }

    private val classifier = NetworkClassifierV2(context)
    private val executor = Executors.newScheduledThreadPool(1)
    private var statsTask: ScheduledFuture<*>? = null
    private var eventSink: EventChannel.EventSink? = null

    init {
        classifier.initialize()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVpn" -> handleStartVpn(call, result)
            "stopVpn" -> handleStopVpn(result)
            "getInstalledApps" -> handleGetApps(result)
            "classifyNetwork" -> handleClassify(result)
            else -> result.notImplemented()
        }
    }

    private fun handleStartVpn(call: MethodCall, result: MethodChannel.Result) {
        val packages = call.argument<List<String>>("allowedPackages") ?: emptyList()
        val profile   = call.argument<String>("profile") ?: "CELLULAR"

        if (profile == "GLOBAL") {
            stopVpnService()
            result.success(false)
            return
        }

        val prepareIntent = VpnService.prepare(context)
        if (prepareIntent != null) {
            result.error("VPN_PERMISSION_REQUIRED", "VPN permission required", null)
            return
        }

        // Resolve target package + UID (first entry in the list)
        val targetPkg = packages.firstOrNull() ?: ""
        val targetUid: Int = if (targetPkg.isNotEmpty()) {
            try {
                context.packageManager.getPackageUid(targetPkg, 0)
            } catch (e: Exception) {
                Log.w(TAG, "Cannot resolve UID for $targetPkg: ${e.message}")
                TrafficStats.UNSUPPORTED
            }
        } else {
            TrafficStats.UNSUPPORTED
        }

        val intent = Intent(context, AdenVpnService::class.java).apply {
            action = AdenVpnService.ACTION_START
            putExtra(AdenVpnService.EXTRA_TARGET_PKG, targetPkg)
            putExtra(AdenVpnService.EXTRA_TARGET_UID, targetUid)
            putExtra(AdenVpnService.EXTRA_PROFILE, profile)
        }
        context.startForegroundService(intent)
        Log.i(TAG, "VPN start requested | profile=$profile | target=$targetPkg | uid=$targetUid")
        result.success(true)
    }

    private fun handleStopVpn(result: MethodChannel.Result) {
        stopVpnService()
        result.success(true)
    }

    private fun stopVpnService() {
        val intent = Intent(context, AdenVpnService::class.java).apply {
            action = AdenVpnService.ACTION_STOP
        }
        context.startService(intent)
    }

    private fun handleGetApps(result: MethodChannel.Result) {
        executor.execute {
            try {
                val pm = context.packageManager
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    PackageManager.MATCH_UNINSTALLED_PACKAGES.toLong().toInt()
                } else {
                    0
                }
                val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                    .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
                    .sortedBy { pm.getApplicationLabel(it).toString() }

                val appList = packages.map { info ->
                    val name = pm.getApplicationLabel(info).toString()
                    val icon = try {
                        val drawable = pm.getApplicationIcon(info.packageName)
                        encodeIconToBase64(drawable)
                    } catch (_: Exception) { null }

                    mapOf(
                        "pkg" to info.packageName,
                        "name" to name,
                        "icon" to icon,
                    )
                }
                result.success(appList)
            } catch (e: Exception) {
                Log.e(TAG, "getInstalledApps error", e)
                result.error("APPS_ERROR", e.message, null)
            }
        }
    }

    private fun handleClassify(result: MethodChannel.Result) {
        executor.execute {
            val state = AdenVpnService.currentAiState
            result.success(state.name)   // "NORMAL"|"DEGRADED"|"EMERGENCY"|"DEEP_FREEZE"
        }
    }

    private fun encodeIconToBase64(drawable: Drawable): String? {
        return try {
            val bitmap = drawableToBitmap(drawable)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 70, stream)
            Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, 64, 64, true)
        }
        val bitmap = Bitmap.createBitmap(64, 64, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    // ── EventChannel (live stats) ──────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        statsTask = executor.scheduleAtFixedRate({
            try {
                // downloadBytes / uploadBytes are now byte-deltas per second from TrafficStats
                val downKbps = AdenVpnService.downloadBytes / 1024.0
                val upKbps   = AdenVpnService.uploadBytes   / 1024.0
                val stats = mapOf(
                    "down_kbps" to downKbps,
                    "up_kbps"   to upKbps,
                    "latency"   to AdenVpnService.lastLatencyMs,
                    "ai_state"  to AdenVpnService.currentAiState.name,
                    "is_active" to AdenVpnService.isRunning,
                    "target_pkg" to AdenVpnService.targetPkg,
                )
                eventSink?.success(stats)
            } catch (e: Exception) {
                Log.e(TAG, "Stats event error", e)
            }
        }, 0, 1, TimeUnit.SECONDS)
    }

    override fun onCancel(arguments: Any?) {
        statsTask?.cancel(false)
        statsTask = null
        eventSink = null
    }

    fun dispose() {
        classifier.close()
        executor.shutdownNow()
    }
}
