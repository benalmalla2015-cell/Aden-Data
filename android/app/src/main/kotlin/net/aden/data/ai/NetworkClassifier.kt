package net.aden.data.ai

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.SystemClock
import android.util.Log
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.net.InetAddress
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel

/**
 * NetworkClassifier — TFLite-based network quality classifier.
 * Input features: [latency_ms, jitter_ms, signal_dbm, link_speed_mbps, conn_type]
 * Output classes: 0=GOOD, 1=WEAK, 2=CONGESTED
 *
 * Model file: assets/models/net_quality.tflite (~40 KB Decision Tree model)
 * Inspired by: Android-TensorFlow-Lite-Example by amitshekhariitbhu
 */
class NetworkClassifier(private val context: Context) {

    companion object {
        private const val TAG = "NetworkClassifier"
        private const val MODEL_FILE = "models/net_quality.tflite"
        private const val INPUT_SIZE = 5
        private const val OUTPUT_SIZE = 3
        const val LABEL_GOOD = "GOOD"
        const val LABEL_WEAK = "WEAK"
        const val LABEL_CONGESTED = "CONGESTED"
    }

    private var interpreter: Interpreter? = null

    fun initialize() {
        try {
            val model = loadModelFile()
            interpreter = Interpreter(model, Interpreter.Options().apply {
                numThreads = 2
                useXNNPACK = true
            })
            Log.i(TAG, "TFLite model loaded successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load TFLite model, using heuristic fallback", e)
            interpreter = null
        }
    }

    fun classify(): String {
        val features = collectNetworkFeatures()
        Log.d(TAG, "Features: latency=${features[0]}, jitter=${features[1]}, " +
                "signal=${features[2]}, speed=${features[3]}, type=${features[4]}")

        return if (interpreter != null) {
            runTFLite(features)
        } else {
            heuristicClassify(features)
        }
    }

    private fun runTFLite(features: FloatArray): String {
        return try {
            val inputBuffer = ByteBuffer.allocateDirect(INPUT_SIZE * 4).apply {
                order(ByteOrder.nativeOrder())
                features.forEach { putFloat(it) }
                rewind()
            }
            val output = Array(1) { FloatArray(OUTPUT_SIZE) }
            interpreter!!.run(inputBuffer, output)

            val scores = output[0]
            val maxIndex = scores.indices.maxByOrNull { scores[it] } ?: 0
            when (maxIndex) {
                0 -> LABEL_GOOD
                1 -> LABEL_WEAK
                2 -> LABEL_CONGESTED
                else -> LABEL_GOOD
            }
        } catch (e: Exception) {
            Log.e(TAG, "TFLite inference error", e)
            heuristicClassify(features)
        }
    }

    /** Fallback rule-based classifier when model file is unavailable */
    private fun heuristicClassify(features: FloatArray): String {
        val latency = features[0]
        val signal = features[2]
        val speed = features[3]

        return when {
            latency > 300 || speed < 1f -> LABEL_CONGESTED
            latency > 100 || signal < -80f -> LABEL_WEAK
            else -> LABEL_GOOD
        }
    }

    private fun collectNetworkFeatures(): FloatArray {
        val latency = measureLatencyMs()
        val jitter = measureJitterMs(latency)
        val (signalDbm, linkSpeedMbps) = getWifiInfo()
        val connType = getConnectionType()

        return floatArrayOf(
            latency.toFloat(),
            jitter.toFloat(),
            signalDbm.toFloat(),
            linkSpeedMbps.toFloat(),
            connType.toFloat(),
        )
    }

    private fun measureLatencyMs(): Long {
        return try {
            val start = SystemClock.elapsedRealtime()
            InetAddress.getByName("8.8.8.8")
            SystemClock.elapsedRealtime() - start
        } catch (e: Exception) {
            999L
        }
    }

    private fun measureJitterMs(baseLatency: Long): Long {
        return try {
            val start = SystemClock.elapsedRealtime()
            InetAddress.getByName("8.8.4.4")
            val latency2 = SystemClock.elapsedRealtime() - start
            Math.abs(latency2 - baseLatency)
        } catch (e: Exception) {
            50L
        }
    }

    private fun getWifiInfo(): Pair<Int, Int> {
        return try {
            val wifiManager = context.applicationContext
                .getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val info = wifiManager?.connectionInfo
            val signal = info?.rssi ?: -100
            val speed = info?.linkSpeed ?: 0
            Pair(signal, speed)
        } catch (e: Exception) {
            Pair(-100, 0)
        }
    }

    private fun getConnectionType(): Int {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
                    as? ConnectivityManager ?: return 0
            val network = cm.activeNetwork ?: return 0
            val caps = cm.getNetworkCapabilities(network) ?: return 0
            when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> 1
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> 2
                else -> 0
            }
        } catch (e: Exception) {
            0
        }
    }

    private fun loadModelFile(): MappedByteBuffer {
        val assetManager = context.assets
        val fileDescriptor = assetManager.openFd(MODEL_FILE)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        return fileChannel.map(
            FileChannel.MapMode.READ_ONLY,
            fileDescriptor.startOffset,
            fileDescriptor.declaredLength,
        )
    }

    fun close() {
        interpreter?.close()
        interpreter = null
    }
}
