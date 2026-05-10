package net.aden.data.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.TrafficStats
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import net.aden.data.aden_data.MainActivity
import net.aden.data.ai.NetworkClassifierV2
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.Socket
import java.net.InetSocketAddress
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * AdenVpnService v2 — Inverted VPN (WRAPPER_MODE).
 *
 * Architecture:
 *  - Target app → addDisallowedApplication → bypasses VPN → 100% native speed.
 *  - All other apps → enter VPN tunnel → packets are silently DROPPED.
 *  - In EMERGENCY/DEEP_FREEZE: additionally inject TCP RST to disconnect other
 *    apps' heavy connections immediately instead of letting them time-out.
 *  - Bandwidth measured via TrafficStats.getUidRxBytes(targetUid) for real KB/s.
 */
class AdenVpnService : VpnService() {

    companion object {
        const val CHANNEL_ID    = "aden_vpn_channel"
        const val NOTIF_ID      = 1001
        const val TAG           = "AdenVPN"
        const val ACTION_START  = "net.aden.data.START_VPN"
        const val ACTION_STOP   = "net.aden.data.STOP_VPN"
        const val EXTRA_PROFILE     = "profile"
        const val EXTRA_TARGET_PKG  = "target_pkg"
        const val EXTRA_TARGET_UID  = "target_uid"

        // ── Live stats — read by VpnBridge every second ───────────────────────
        @Volatile var isRunning     = false
        @Volatile var downloadBytes : Long = 0L   // bytes received by target app this second
        @Volatile var uploadBytes   : Long = 0L   // bytes sent by target app this second
        @Volatile var lastLatencyMs : Int  = 0    // TCP connect latency to 8.8.8.8:53

        // ── State exposed to Flutter ──────────────────────────────────────────
        @Volatile var currentAiState : AiState = AiState.NORMAL
        @Volatile var targetPkg      : String  = ""
        @Volatile var targetUid      : Int     = TrafficStats.UNSUPPORTED
    }

    private var vpnInterface  : ParcelFileDescriptor? = null
    private val running         = AtomicBoolean(false)
    private var readerThread  : Thread? = null
    private var classifier    : NetworkClassifierV2? = null

    private val aiExecutor  = Executors.newSingleThreadScheduledExecutor()
    private val bwExecutor  = Executors.newSingleThreadScheduledExecutor()
    private var bwTask      : ScheduledFuture<*>? = null
    private val mainHandler   = Handler(Looper.getMainLooper())

    private var prevRxBytes   = 0L
    private var prevTxBytes   = 0L
    private val throughputWindow = ArrayDeque<Long>(5)

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) { stopEngine(); return START_NOT_STICKY }

        val tPkg  = intent?.getStringExtra(EXTRA_TARGET_PKG)  ?: ""
        val tUid  = intent?.getIntExtra(EXTRA_TARGET_UID, TrafficStats.UNSUPPORTED)
                    ?: TrafficStats.UNSUPPORTED
        val profile = intent?.getStringExtra(EXTRA_PROFILE) ?: "CELLULAR"

        startEngine(tPkg, tUid, profile)
        return START_STICKY
    }

    // ── Engine ────────────────────────────────────────────────────────────────

    private fun startEngine(tPkg: String, tUid: Int, profile: String) {
        if (running.getAndSet(true)) return

        if (profile == "GLOBAL") {
            running.set(false)
            stopSelf()
            return
        }

        targetPkg = tPkg
        targetUid = tUid

        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification(AiState.NORMAL, tPkg))

        if (!buildVpnInterface(tPkg)) {
            running.set(false)
            stopSelf()
            return
        }

        isRunning = true
        currentAiState = AiState.NORMAL

        classifier = NetworkClassifierV2(applicationContext).also { it.initialize() }

        startDropAllLoop()
        startBandwidthMonitor(tUid)
        startAiMonitor(tPkg, tUid)

        Log.i(TAG, "VPN started | profile=$profile | target=$tPkg | uid=$tUid")
    }

    /**
     * Build VPN interface using WRAPPER_MODE:
     *  - addDisallowedApplication(targetPkg) → target bypasses VPN
     *  - addDisallowedApplication(packageName) → our own app bypasses VPN
     *  - Everything else enters VPN tunnel and gets DROPPED.
     */
    private fun buildVpnInterface(tPkg: String): Boolean {
        return try {
            val builder = Builder()
                .setSession("عدن داتا")
                .addAddress("10.0.0.2", 24)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("1.1.1.1")
                .setMtu(1500)
                .setBlocking(true)

            // Our own app always bypasses (keep Flutter ↔ service comms alive)
            try { builder.addDisallowedApplication(packageName) } catch (_: Exception) {}

            // Target app bypasses → gets full native speed
            if (tPkg.isNotEmpty()) {
                try {
                    builder.addDisallowedApplication(tPkg)
                    Log.i(TAG, "Target $tPkg will bypass VPN (native speed)")
                } catch (e: Exception) {
                    Log.w(TAG, "addDisallowedApplication($tPkg) failed: ${e.message}")
                }
            }

            val fd = builder.establish()
            if (fd == null) {
                Log.e(TAG, "establish() returned null — VPN permission not granted?")
                return false
            }
            protect(fd.fd)
            vpnInterface?.close()
            vpnInterface = fd
            true
        } catch (e: Exception) {
            Log.e(TAG, "buildVpnInterface error", e)
            false
        }
    }

    /**
     * DROP-ALL packet loop.
     * Reads packets from other apps entering the VPN tunnel.
     *  - NORMAL/DEGRADED: silently drop (timeout approach — app will retry later)
     *  - EMERGENCY/DEEP_FREEZE: inject TCP RST to disconnect heavy connections fast.
     */
    private fun startDropAllLoop() {
        readerThread?.interrupt()
        readerThread = Thread({
            val fd           = vpnInterface?.fileDescriptor ?: return@Thread
            val inputStream  = FileInputStream(fd)
            val outputStream = FileOutputStream(fd)
            val rawBuf       = ByteArray(32_767)
            Log.i(TAG, "DROP-ALL loop started")

            while (running.get()) {
                try {
                    val length = inputStream.read(rawBuf)
                    if (length <= 0) continue
                    val packet = rawBuf.copyOf(length)

                    // In emergency states: actively RST TCP to disconnect heavy streams
                    val state = currentAiState
                    if (state == AiState.EMERGENCY || state == AiState.DEEP_FREEZE) {
                        if (isTcpPacket(packet)) {
                            try { PacketSurgeon.killTcp(packet, outputStream) } catch (_: Exception) {}
                        }
                    }
                    // else: pure silent drop — no writeback at all
                } catch (e: Exception) {
                    if (running.get()) Log.e(TAG, "DROP loop error", e)
                }
            }
            Log.i(TAG, "DROP-ALL loop exited")
        }, "aden-drop-loop")
        readerThread?.isDaemon = true
        readerThread?.start()
    }

    /** Returns true when the raw IP packet is TCP (protocol byte = 6). */
    private fun isTcpPacket(packet: ByteArray): Boolean =
        packet.size >= 20 && (packet[9].toInt() and 0xFF) == 6

    // ── Bandwidth monitor (TrafficStats) ─────────────────────────────────────

    private fun startBandwidthMonitor(uid: Int) {
        bwTask?.cancel(false)
        if (uid == TrafficStats.UNSUPPORTED || uid <= 0) {
            Log.w(TAG, "Invalid UID $uid — TrafficStats monitor skipped")
            downloadBytes = 0L; uploadBytes = 0L
            return
        }

        prevRxBytes = TrafficStats.getUidRxBytes(uid).coerceAtLeast(0)
        prevTxBytes = TrafficStats.getUidTxBytes(uid).coerceAtLeast(0)

        var latencyTick = 0

        bwTask = bwExecutor.scheduleAtFixedRate({
            try {
                val rx = TrafficStats.getUidRxBytes(uid).coerceAtLeast(0)
                val tx = TrafficStats.getUidTxBytes(uid).coerceAtLeast(0)
                downloadBytes = (rx - prevRxBytes).coerceAtLeast(0)
                uploadBytes   = (tx - prevTxBytes).coerceAtLeast(0)
                prevRxBytes   = rx
                prevTxBytes   = tx

                // Measure latency every 10 seconds
                latencyTick++
                if (latencyTick >= 10) {
                    latencyTick = 0
                    measureLatency()
                }
            } catch (e: Exception) {
                Log.e(TAG, "BW monitor error", e)
            }
        }, 1, 1, TimeUnit.SECONDS)
    }

    private fun measureLatency() {
        try {
            val socket = Socket()
            protect(socket)
            val start = SystemClock.elapsedRealtime()
            socket.connect(InetSocketAddress("8.8.8.8", 53), 3000)
            lastLatencyMs = (SystemClock.elapsedRealtime() - start).toInt()
            socket.close()
        } catch (_: Exception) {
            lastLatencyMs = 999
        }
    }

    // ── AI Monitor ────────────────────────────────────────────────────────────

    private fun startAiMonitor(tPkg: String, tUid: Int) {
        aiExecutor.scheduleAtFixedRate({
            try {
                val kbps = downloadBytes / 1024f
                throughputWindow.addLast(kbps.toLong())
                if (throughputWindow.size > 5) throughputWindow.removeFirst()

                val newState = classifier?.classify(kbps) ?: AiState.NORMAL
                if (newState != currentAiState) {
                    currentAiState = newState
                    Log.i(TAG, "AI → $newState | ${kbps.toInt()} KB/s")
                    mainHandler.post { updateNotification(newState, tPkg) }
                }
            } catch (e: Exception) {
                Log.e(TAG, "AI monitor error", e)
            }
        }, 2, 1, TimeUnit.SECONDS)
    }

    // ── Stop ──────────────────────────────────────────────────────────────────

    fun stopEngine() {
        if (!running.getAndSet(false)) return
        bwTask?.cancel(false)
        aiExecutor.shutdownNow()
        readerThread?.interrupt()
        readerThread = null
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        classifier?.close()
        classifier = null
        isRunning      = false
        currentAiState = AiState.NORMAL
        downloadBytes  = 0L
        uploadBytes    = 0L
        lastLatencyMs  = 0
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.i(TAG, "VPN stopped")
    }

    override fun onRevoke() { stopEngine(); super.onRevoke() }
    override fun onDestroy() { stopEngine(); super.onDestroy() }

    // ── Notification ──────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "عدن داتا — الحماية النشطة",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "إشعار تشغيل محرك التركيز"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(ch)
        }
    }

    private fun appLabel(pkg: String): String = try {
        packageManager.getApplicationLabel(
            packageManager.getApplicationInfo(pkg, 0)
        ).toString()
    } catch (_: Exception) { pkg }

    private fun buildNotification(state: AiState, tPkg: String): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val label = if (tPkg.isNotEmpty()) appLabel(tPkg) else "بدون هدف"
        val (title, text) = when (state) {
            AiState.DEEP_FREEZE ->
                "عدن داتا — وضع الإنقاذ" to "شبكة حرجة < 20 KB/s"
            AiState.EMERGENCY   ->
                "عدن داتا — وضع الطوارئ" to "شبكة ضعيفة جداً"
            AiState.DEGRADED    ->
                "عدن داتا — شبكة ضعيفة" to "مُركَّز على: $label"
            AiState.NORMAL      ->
                "عدن داتا — يعمل" to "مُركَّز على: $label"
        }
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(state: AiState, tPkg: String) {
        getSystemService(NotificationManager::class.java)
            ?.notify(NOTIF_ID, buildNotification(state, tPkg))
    }
}
