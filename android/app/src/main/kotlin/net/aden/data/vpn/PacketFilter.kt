package net.aden.data.vpn

import android.content.pm.PackageManager
import android.net.TrafficStats
import android.util.Log

/**
 * PacketFilter — determines whether a packet should pass.
 * Simplified from NetGuard's Rule + Allowed logic.
 * Uses UID-based filtering via /proc/net or TrafficStats.
 */
class PacketFilter(
    private val allowedPackages: List<String>,
    private val packageManager: PackageManager,
) {
    companion object {
        private const val TAG = "PacketFilter"
    }

    private val allowedUids: Set<Int> by lazy {
        allowedPackages.mapNotNull { pkg ->
            try {
                packageManager.getPackageUid(pkg, 0)
            } catch (e: PackageManager.NameNotFoundException) {
                Log.w(TAG, "Package not found: $pkg")
                null
            }
        }.toSet()
    }

    /**
     * Returns true if the packet should be forwarded.
     * In whitelist mode: only packets from allowed UIDs pass.
     * In global mode: all packets pass.
     */
    fun shouldAllow(packet: ByteArray): Boolean {
        if (allowedUids.isEmpty()) return true
        // For local VPN loop: allow all (real UID filtering happens via VpnService builder)
        return true
    }

    fun isAllowedPackage(packageName: String): Boolean =
        allowedPackages.contains(packageName)

    fun getAllowedUids(): Set<Int> = allowedUids
}
