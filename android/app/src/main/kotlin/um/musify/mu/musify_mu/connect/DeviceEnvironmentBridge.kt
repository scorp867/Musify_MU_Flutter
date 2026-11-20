package um.musify.mu.musify_mu.connect

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android Device Environment & Hardware Identity Bridge for Spotify Connect.
 *
 * Replicates Spotify Android's device identity and hardware environment inspection:
 * - Stable Android ID (`Settings.Secure.ANDROID_ID`, fallback `"0"`): `p199p/bus.java:34-41`.
 * - User-facing device display name resolution (`BluetoothAdapter.getName()` guarded by
 *   `BLUETOOTH_CONNECT` on API >= 31, `Settings.Global.DEVICE_NAME`, `bluetooth_name`,
 *   falling back to `Build.MODEL`): `p199p/dyl1.java:2282-2302`.
 * - Device form-factor classification (`CHROMEBOOK=14` via `org.chromium.arc`,
 *   `android.hardware.type.pc`, or `.+_cheets|cheets_.+`; `TABLET=2` via
 *   `smallestScreenWidthDp >= 600`; else `SMARTPHONE=3`): `p199p/t3t.java:56-79`, `p199p/w3t.java:16`.
 * - `STREAM_MUSIC` max volume steps and initial normalized volume ratio:
 *   `p199p/gsl.java:248`, `p199p/mhk.java:264-298`, `p199p/esq.java:14-24`.
 * - Runtime permission introspection for `BLUETOOTH_CONNECT` and `NEARBY_WIFI_DEVICES`:
 *   `p199p/fkm0.java:53-118`, `p199p/asq.java:74-173`.
 */
class DeviceEnvironmentBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "[CONNECT-KOTLIN]"
        const val CHANNEL_NAME = "um.musify.mu/connect/device_environment"
        private const val DEFAULT_ANDROID_ID_FALLBACK = "0"
        private const val DEFAULT_VOLUME_STEPS = 32
        private const val TABLET_SMALLEST_WIDTH_DP = 600
        private val CHEETS_DEVICE_REGEX = Regex(".+_cheets|cheets_.+")
    }

    private var methodChannel: MethodChannel? = null

    fun register(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        methodChannel = channel
        Log.i(TAG, "DeviceEnvironmentBridge registered on $CHANNEL_NAME")
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        Log.i(TAG, "DeviceEnvironmentBridge detached")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceEnvironment" -> {
                try {
                    val env = buildDeviceEnvironmentSnapshot()
                    result.success(env)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to query device environment: ${e.message}", e)
                    result.error(
                        "DEVICE_ENVIRONMENT_ERROR",
                        "Failed to collect device environment: ${e.message}",
                        null
                    )
                }
            }
            "openAppSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.fromParts("package", context.packageName, null)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to open application details settings: ${e.message}", e)
                    result.error(
                        "OPEN_SETTINGS_ERROR",
                        "Failed to open application settings: ${e.message}",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun buildDeviceEnvironmentSnapshot(): Map<String, Any> {
        val hasBtConnect = hasBluetoothConnectPermission()
        val hasNearbyWifi = hasNearbyWifiPermission()
        val androidId = resolveAndroidId()
        val deviceName = resolveDeviceName(hasBtConnect)
        val brand = Build.BRAND?.trim()?.takeIf { it.isNotEmpty() } ?: "Android"
        val model = Build.MODEL?.trim()?.takeIf { it.isNotEmpty() } ?: "Android"
        val osVersion = Build.VERSION.RELEASE?.trim()?.takeIf { it.isNotEmpty() }
            ?: Build.VERSION.SDK_INT.toString()
        val sdkInt = Build.VERSION.SDK_INT
        val packageInfo = resolvePackageInfo()
        val appVersionName = packageInfo?.versionName?.trim()?.takeIf { it.isNotEmpty() } ?: "1.0.0"
        val appVersionCode = packageInfo?.longVersionCode ?: 1L
        val deviceTypeWire = classifyDeviceTypeWire()

        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val maxMusicVolumeSteps = try {
            audioManager?.getStreamMaxVolume(AudioManager.STREAM_MUSIC)?.coerceAtLeast(1)
                ?: DEFAULT_VOLUME_STEPS
        } catch (e: Exception) {
            Log.w(TAG, "Unable to read getStreamMaxVolume(STREAM_MUSIC), using $DEFAULT_VOLUME_STEPS: ${e.message}")
            DEFAULT_VOLUME_STEPS
        }

        val currentMusicVolumeStep = try {
            audioManager?.getStreamVolume(AudioManager.STREAM_MUSIC)?.coerceIn(0, maxMusicVolumeSteps)
                ?: (maxMusicVolumeSteps / 2)
        } catch (e: Exception) {
            Log.w(TAG, "Unable to read getStreamVolume(STREAM_MUSIC): ${e.message}")
            maxMusicVolumeSteps / 2
        }

        val currentMusicVolumeRatio = (currentMusicVolumeStep.toDouble() / maxMusicVolumeSteps.toDouble())
            .coerceIn(0.0, 1.0)

        return mapOf(
            "androidId" to androidId,
            "deviceName" to deviceName,
            "brand" to brand,
            "model" to model,
            "osVersion" to osVersion,
            "sdkInt" to sdkInt,
            "appVersionName" to appVersionName,
            "appVersionCode" to appVersionCode,
            "deviceTypeWire" to deviceTypeWire,
            "maxMusicVolumeSteps" to maxMusicVolumeSteps,
            "currentMusicVolumeRatio" to currentMusicVolumeRatio,
            "hasBluetoothConnectPermission" to hasBtConnect,
            "hasNearbyWifiPermission" to hasNearbyWifi
        )
    }

    /**
     * Reads `Settings.Secure.ANDROID_ID` per `p199p/bus.java:34-41`, falling back to `"0"`.
     */
    private fun resolveAndroidId(): String {
        return try {
            val raw = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ANDROID_ID
            )?.trim()
            if (raw.isNullOrEmpty()) DEFAULT_ANDROID_ID_FALLBACK else raw
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read Settings.Secure.ANDROID_ID: ${e.message}")
            DEFAULT_ANDROID_ID_FALLBACK
        }
    }

    /**
     * Resolves user-configured device name per `p199p/dyl1.java:2282-2302`:
     * 1. `BluetoothAdapter.getName()` when `BLUETOOTH_CONNECT` is granted.
     * 2. `Settings.Global.DEVICE_NAME` (`"device_name"`).
     * 3. `Settings.Secure.getString("bluetooth_name")`.
     * 4. `Build.MODEL`.
     */
    @SuppressLint("MissingPermission")
    private fun resolveDeviceName(hasBtConnectPermission: Boolean): String {
        if (hasBtConnectPermission) {
            try {
                val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val btName = bluetoothManager?.adapter?.name?.trim()
                if (!btName.isNullOrEmpty()) {
                    return btName
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "SecurityException reading BluetoothAdapter.name: ${e.message}")
            } catch (e: Exception) {
                Log.w(TAG, "Error reading BluetoothAdapter.name: ${e.message}")
            }
        }

        try {
            val globalName = Settings.Global.getString(
                context.contentResolver,
                Settings.Global.DEVICE_NAME
            )?.trim()
            if (!globalName.isNullOrEmpty()) {
                return globalName
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read Settings.Global.DEVICE_NAME: ${e.message}")
        }

        try {
            val secureBtName = Settings.Secure.getString(
                context.contentResolver,
                "bluetooth_name"
            )?.trim()
            if (!secureBtName.isNullOrEmpty()) {
                return secureBtName
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read Settings.Secure bluetooth_name: ${e.message}")
        }

        return Build.MODEL?.trim()?.takeIf { it.isNotEmpty() } ?: "Android Device"
    }

    /**
     * Classifies Android hardware form-factor per `p199p/t3t.java:56-79` and `p199p/w3t.java:16`:
     * - `"CHROMEBOOK"` (`DeviceType.CHROMEBOOK = 14`)
     * - `"TABLET"` (`DeviceType.TABLET = 2`)
     * - `"SMARTPHONE"` (`DeviceType.SMARTPHONE = 3`)
     */
    private fun classifyDeviceTypeWire(): String {
        val pm = context.packageManager
        val isArcOrPc = try {
            pm.hasSystemFeature("org.chromium.arc") ||
                pm.hasSystemFeature("org.chromium.arc.device_management") ||
                pm.hasSystemFeature(PackageManager.FEATURE_PC) ||
                (Build.DEVICE?.matches(CHEETS_DEVICE_REGEX) == true)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to inspect Chromebook system features: ${e.message}")
            false
        }
        if (isArcOrPc) {
            return "CHROMEBOOK"
        }

        val smallestWidthDp = try {
            context.resources.configuration.smallestScreenWidthDp
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read smallestScreenWidthDp: ${e.message}")
            0
        }
        return if (smallestWidthDp >= TABLET_SMALLEST_WIDTH_DP) {
            "TABLET"
        } else {
            "SMARTPHONE"
        }
    }

    private fun resolvePackageInfo(): PackageInfo? {
        return try {
            val pm = context.packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(
                    context.packageName,
                    PackageManager.PackageInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(context.packageName, 0)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read PackageInfo: ${e.message}")
            null
        }
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_CONNECT
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun hasNearbyWifiPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.NEARBY_WIFI_DEVICES
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_WIFI_STATE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }
}
