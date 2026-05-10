package net.aden.data.ai

import android.content.Context
import net.aden.data.vpn.AiState

/**
 * NetworkClassifier — legacy stub.
 * Delegates to NetworkClassifierV2 (custom binary Decision Tree, no TFLite).
 * Kept for backward-compat with VpnBridge references.
 */
@Deprecated("Use NetworkClassifierV2 directly")
class NetworkClassifier(context: Context) {

    private val v2 = NetworkClassifierV2(context)

    fun initialize() = v2.initialize()

    fun classify(): String = when (v2.classify()) {
        AiState.NORMAL     -> "GOOD"
        AiState.DEGRADED   -> "WEAK"
        AiState.EMERGENCY  -> "CONGESTED"
        AiState.DEEP_FREEZE -> "CONGESTED"
    }

    fun close() = v2.close()
}
