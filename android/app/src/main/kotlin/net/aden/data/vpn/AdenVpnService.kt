package net.aden.data.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import net.aden.data.MainActivity
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetAddress
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/**
 * AdenVpnService — Local VPN that whitelists selected UIDs.
 * Extracted and simplified from M66B/NetGuard VpnService logic.
 * Zero external traffic. Only routes packets on-device.
 */
class AdenVpnService : VpnService() {

    companion object {
        const val CHANNEL_ID = "aden_vpn_channel"
        const val NOTIF_ID = 1001
        const val TAG = "AdenVPN"
        const val ACTION_START = "net.aden.data.START_VPN"
        const val ACTION_STOP = "net.aden.data.STOP_VPN"
        const val EXTRA_PACKAGES = "allowed_packages"
        const val EXTRA_PROFILE = "profile"

        @Volatile var isRunning = false

        // Live stats (updated by packet loop)
        @Volatile var downloadBytes: Long = 0L
        @Volatile var uploadBytes: Long = 0L
        @Volatile var lastLatencyMs: Int = 0
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val running = AtomicBoolean(false)
    private var packetFilter: PacketFilter? = null
    private var readerThread: Thread? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopEngine()
            return START_NOT_STICKY
        }

        val packages = intent?.getStringArrayListExtra(EXTRA_PACKAGES) ?: arrayListOf()
        val profile = intent?.getStringExtra(EXTRA_PROFILE) ?: "CELLULAR"

        startEngine(packages, profile)
        return START_STICKY
    }

    private fun startEngine(allowedPackages: List<String>, profile: String) {
        if (running.getAndSet(true)) return

        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification())

        val builder = Builder()
            .setSession("عدن داتا VPN")
            .addAddress("10.0.0.2", 24)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4")
            .setMtu(1500)
            .setBlocking(true)

        // Allow selected packages — all others are routed through VPN (and dropped)
        if (allowedPackages.isNotEmpty()) {
            allowedPackages.forEach { pkg ->
                try {
                    builder.addAllowedApplication(pkg)
                } catch (e: Exception) {
                    Log.w(TAG, "Unknown package: $pkg")
                }
            }
            // Always allow our own app
            try { builder.addAllowedApplication(packageName) } catch (_: Exception) {}
        }

        // In GLOBAL mode: establish VPN but allow all apps
        if (profile == "GLOBAL") {
            stopEngine()
            return
        }

        vpnInterface = protect(builder.establish()!!)

        packetFilter = PacketFilter(
            allowedPackages = allowedPackages,
            packageManager = packageManager,
        )

        isRunning = true
        resetStats()
        startPacketLoop()
        Log.i(TAG, "VPN engine started | profile=$profile | allowed=${allowedPackages.size} apps")
    }

    private fun startPacketLoop() {
        readerThread = Thread({
            val vpnFd = vpnInterface?.fileDescriptor ?: return@Thread
            val inputStream = FileInputStream(vpnFd)
            val outputStream = FileOutputStream(vpnFd)
            val buffer = ByteBuffer.allocate(32767)

            while (running.get()) {
                try {
                    buffer.clear()
                    val length = inputStream.read(buffer.array())
                    if (length <= 0) continue

                    buffer.limit(length)
                    uploadBytes += length

                    // Forward allowed packets back to the interface
                    // In a real implementation, packets are forwarded to the real network
                    // Here we track stats only (device VPN loop)
                    val packetBytes = buffer.array().copyOf(length)
                    if (packetFilter?.shouldAllow(packetBytes) == true) {
                        outputStream.write(packetBytes)
                        downloadBytes += length
                    }
                } catch (e: Exception) {
                    if (running.get()) Log.e(TAG, "Packet loop error", e)
                }
            }
        }, "aden-packet-loop")
        readerThread?.isDaemon = true
        readerThread?.start()
    }

    fun stopEngine() {
        if (!running.getAndSet(false)) return
        readerThread?.interrupt()
        readerThread = null
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error closing VPN interface", e)
        }
        vpnInterface = null
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        Log.i(TAG, "VPN engine stopped")
    }

    override fun onRevoke() {
        stopEngine()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopEngine()
        super.onDestroy()
    }

    private fun protect(fd: ParcelFileDescriptor): ParcelFileDescriptor {
        protect(fd.fd)
        return fd
    }

    private fun resetStats() {
        downloadBytes = 0L
        uploadBytes = 0L
        lastLatencyMs = 0
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "عدن داتا — الحماية النشطة",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "إشعار تشغيل محرك الحماية"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("عدن داتا — المحرك يعمل")
            .setContentText("جاري تركيز البيانات على التطبيق المختار")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
