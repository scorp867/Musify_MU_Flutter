package um.musify.mu.musify_mu.connect

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Local Audio Output Route & Peripheral Monitor for Spotify Connect.
 *
 * Replicates Spotify Android's peripheral discovery and `NotifyAudioRouteChanged` pipeline:
 * - Aggregates physical and Bluetooth audio output peripherals (`p199p/jiq.java`, `p199p/C2426wj.java`).
 * - Tracks `AudioManager.getDevices(GET_DEVICES_OUTPUTS)` and `AudioDeviceCallback` for Bluetooth
 *   (`TYPE_BLUETOOTH_A2DP=8`, `TYPE_BLE_HEADSET=26`, `TYPE_BLE_SPEAKER=27`, `TYPE_BLE_BROADCAST=30`)
 *   and wired (`TYPE_WIRED_HEADSET=3`, `TYPE_WIRED_HEADPHONES=4`, `TYPE_USB_HEADSET=22`,
 *   `TYPE_USB_DEVICE=11`, `TYPE_USB_ACCESSORY=12`, `TYPE_LINE_ANALOG=5`, `TYPE_LINE_DIGITAL=6`,
 *   `TYPE_HDMI=9`, `TYPE_HDMI_ARC=10`, `TYPE_HDMI_EARC=29`):
 *   `p199p/wg7.java:59,79`, `p199p/hh7.java:34,50,112,128`, `p199p/ih7.java:56`.
 * - Observes Bluetooth A2DP / Headset state broadcasts (`ACTION_CONNECTION_STATE_CHANGED`,
 *   `ACTION_PLAYING_STATE_CHANGED`, `BluetoothAdapter.ACTION_STATE_CHANGED`,
 *   `AudioManager.ACTION_AUDIO_BECOMING_NOISY`, `AudioManager.ACTION_HEADSET_PLUG`) and resolves
 *   `BluetoothDevice.getAlias()` / `getName()` + `BluetoothClass` hardware categorization:
 *   `p199p/twa.java`, `p199p/ao8.java:180-194`.
 * - Emits exact `OutputPeripheralConnectionType` (`0..5`) and `OutputPeripheralCategory` (`0..6`)
 *   wire ordinals matching `p199p/k7k.java:4-83`, `ConnectMessages$OutputPeripheral.java`, and
 *   `lib/features/connect/domain/models/output_peripheral.dart:13-20,81-88`.
 */
class AudioRouteMonitor(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "[CONNECT-KOTLIN]"
        const val CONTROL_CHANNEL_NAME = "um.musify.mu/connect/audio_route_control"
        const val EVENTS_CHANNEL_NAME = "um.musify.mu/connect/audio_route_events"

        const val BUILT_IN_SPEAKER_ID = "built_in_speaker"

        // Exact OutputPeripheralConnectionType ordinals (0..5)
        // Must match OutputPeripheralConnectionType in output_peripheral.dart:13-20
        const val CONNECTION_TYPE_UNKNOWN = 0
        const val CONNECTION_TYPE_WIRED = 1
        const val CONNECTION_TYPE_CAR_PROJECTED = 2
        const val CONNECTION_TYPE_BLUETOOTH = 3
        const val CONNECTION_TYPE_AIRPLAY = 4
        const val CONNECTION_TYPE_BUILT_IN_SPEAKER = 5

        // Exact OutputPeripheralCategory ordinals (0..6)
        // Must match OutputPeripheralCategory in output_peripheral.dart:81-88
        const val CATEGORY_UNKNOWN = 0
        const val CATEGORY_CAR = 1
        const val CATEGORY_HEADPHONES = 2
        const val CATEGORY_SPEAKER = 3
        const val CATEGORY_WEARABLE = 4
        const val CATEGORY_GLASSES = 5
        const val CATEGORY_APP = 6

        private const val SYSTEM_UI_PACKAGE = "com.android.systemui"
        private const val ACTION_LAUNCH_MEDIA_OUTPUT_DIALOG =
            "com.android.systemui.action.LAUNCH_MEDIA_OUTPUT_DIALOG"
        private const val EXTRA_PACKAGE_NAME = "package_name"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    private var controlChannel: MethodChannel? = null
    private var eventsChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isMonitoringCallbacks = false
    private var isReceiverRegistered = false
    private var lastEmittedSnapshot: List<Map<String, Any?>>? = null

    private val audioDeviceCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>?) {
            notifyPeripheralsIfChanged()
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>?) {
            notifyPeripheralsIfChanged()
        }
    }

    private val bluetoothAndRouteReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            if (intent == null) return
            mainHandler.post {
                notifyPeripheralsIfChanged()
            }
        }
    }

    fun register(messenger: BinaryMessenger) {
        controlChannel = MethodChannel(messenger, CONTROL_CHANNEL_NAME).apply {
            setMethodCallHandler(this@AudioRouteMonitor)
        }
        eventsChannel = EventChannel(messenger, EVENTS_CHANNEL_NAME).apply {
            setStreamHandler(this@AudioRouteMonitor)
        }
        startHardwareMonitoring()
        Log.i(TAG, "AudioRouteMonitor registered on $CONTROL_CHANNEL_NAME and $EVENTS_CHANNEL_NAME")
    }

    fun detach() {
        stopHardwareMonitoring()
        eventSink = null
        lastEmittedSnapshot = null
        controlChannel?.setMethodCallHandler(null)
        controlChannel = null
        eventsChannel?.setStreamHandler(null)
        eventsChannel = null
        Log.i(TAG, "AudioRouteMonitor detached")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPeripherals" -> {
                try {
                    val snapshot = buildPeripheralsSnapshot()
                    result.success(snapshot)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to query audio output peripherals: ${e.message}", e)
                    result.error(
                        "AUDIO_ROUTE_QUERY_ERROR",
                        "Failed to query audio output peripherals: ${e.message}",
                        null
                    )
                }
            }
            "openSystemOutputSwitcher" -> {
                try {
                    val launched = openSystemOutputSwitcherInternal()
                    result.success(launched)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to open system output switcher: ${e.message}", e)
                    result.error(
                        "OUTPUT_SWITCHER_ERROR",
                        "Failed to open system output switcher: ${e.message}",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startHardwareMonitoring()
        try {
            val initial = buildPeripheralsSnapshot()
            lastEmittedSnapshot = initial
            events?.success(initial)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to emit initial audio route peripherals snapshot: ${e.message}", e)
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startHardwareMonitoring() {
        if (!isMonitoringCallbacks) {
            try {
                audioManager?.registerAudioDeviceCallback(audioDeviceCallback, mainHandler)
                isMonitoringCallbacks = true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to register AudioDeviceCallback: ${e.message}")
            }
        }
        if (!isReceiverRegistered) {
            try {
                val filter = IntentFilter().apply {
                    addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
                    addAction(BluetoothA2dp.ACTION_PLAYING_STATE_CHANGED)
                    addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
                    addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
                    addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
                    addAction(AudioManager.ACTION_HEADSET_PLUG)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.registerReceiver(
                        bluetoothAndRouteReceiver,
                        filter,
                        Context.RECEIVER_NOT_EXPORTED
                    )
                } else {
                    ContextCompat.registerReceiver(
                        context,
                        bluetoothAndRouteReceiver,
                        filter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                }
                isReceiverRegistered = true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to register audio route BroadcastReceiver: ${e.message}")
            }
        }
    }

    private fun stopHardwareMonitoring() {
        if (isMonitoringCallbacks) {
            try {
                audioManager?.unregisterAudioDeviceCallback(audioDeviceCallback)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to unregister AudioDeviceCallback: ${e.message}")
            }
            isMonitoringCallbacks = false
        }
        if (isReceiverRegistered) {
            try {
                context.unregisterReceiver(bluetoothAndRouteReceiver)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to unregister audio route BroadcastReceiver: ${e.message}")
            }
            isReceiverRegistered = false
        }
    }

    private fun notifyPeripheralsIfChanged() {
        val sink = eventSink ?: return
        try {
            val current = buildPeripheralsSnapshot()
            if (current != lastEmittedSnapshot) {
                lastEmittedSnapshot = current
                sink.success(current)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error computing peripherals snapshot on route change: ${e.message}", e)
        }
    }

    private data class ExternalRouteCandidate(
        val id: String,
        val name: String,
        val connectionTypeIndex: Int,
        val categoryIndex: Int,
        val priority: Int,
        val brand: String?,
        val model: String?
    )

    private fun buildPeripheralsSnapshot(): List<Map<String, Any?>> {
        val manager = audioManager
        val outputDevices: Array<AudioDeviceInfo> = try {
            manager?.getDevices(AudioManager.GET_DEVICES_OUTPUTS) ?: emptyArray()
        } catch (e: Exception) {
            Log.w(TAG, "AudioManager.getDevices(GET_DEVICES_OUTPUTS) failed: ${e.message}")
            emptyArray()
        }

        val hasBtConnect = hasBluetoothConnectPermission()
        val btAdapter: BluetoothAdapter? = if (hasBtConnect) {
            try {
                (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
            } catch (e: Exception) {
                Log.w(TAG, "Unable to obtain BluetoothAdapter: ${e.message}")
                null
            }
        } else {
            null
        }

        val candidatesById = LinkedHashMap<String, ExternalRouteCandidate>()
        for (deviceInfo in outputDevices) {
            if (!deviceInfo.isSink) continue
            val candidate = mapAudioDeviceInfoToCandidate(deviceInfo, btAdapter, hasBtConnect)
                ?: continue
            val existing = candidatesById[candidate.id]
            if (existing == null || candidate.priority > existing.priority) {
                candidatesById[candidate.id] = candidate
            }
        }

        val sortedCandidates = candidatesById.values.sortedByDescending { it.priority }
        val activeExternalId: String? = sortedCandidates.firstOrNull()?.id

        val result = ArrayList<Map<String, Any?>>(sortedCandidates.size + 1)

        val phoneBrand = Build.BRAND?.trim()?.takeIf { it.isNotEmpty() }
        val phoneModel = Build.MODEL?.trim()?.takeIf { it.isNotEmpty() }
        val builtInSpeakerName = phoneModel ?: "Phone speaker"
        val isBuiltInSpeakerActive = activeExternalId == null

        result.add(
            mapOf(
                "id" to BUILT_IN_SPEAKER_ID,
                "name" to builtInSpeakerName,
                "isActive" to isBuiltInSpeakerActive,
                "isConnected" to true,
                "connectionTypeIndex" to CONNECTION_TYPE_BUILT_IN_SPEAKER,
                "categoryIndex" to CATEGORY_SPEAKER,
                "brand" to phoneBrand,
                "model" to phoneModel
            )
        )

        for (candidate in sortedCandidates) {
            result.add(
                mapOf(
                    "id" to candidate.id,
                    "name" to candidate.name,
                    "isActive" to (candidate.id == activeExternalId),
                    "isConnected" to true,
                    "connectionTypeIndex" to candidate.connectionTypeIndex,
                    "categoryIndex" to candidate.categoryIndex,
                    "brand" to candidate.brand,
                    "model" to candidate.model
                )
            )
        }

        return result
    }

    private fun mapAudioDeviceInfoToCandidate(
        info: AudioDeviceInfo,
        btAdapter: BluetoothAdapter?,
        hasBtConnect: Boolean
    ): ExternalRouteCandidate? {
        val type = info.type
        return when {
            isBluetoothOutputType(type) -> {
                val rawAddress = try {
                    info.address.trim()
                } catch (e: Exception) {
                    Log.w(TAG, "Unable to read AudioDeviceInfo.address: ${e.message}")
                    ""
                }
                val btDevice = resolveBluetoothDevice(btAdapter, rawAddress, hasBtConnect)
                val productName = info.productName?.toString()?.trim().orEmpty()
                val btName = resolveBluetoothDeviceDisplayName(btDevice, productName, hasBtConnect)
                val categoryIndex = classifyBluetoothCategory(type, btDevice, btName, hasBtConnect)
                val idSuffix = if (rawAddress.isNotEmpty()) rawAddress else "${type}_${info.id}"
                val priority = when (type) {
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> 300
                    else -> 290 // BLE_HEADSET / BLE_SPEAKER / BLE_BROADCAST
                }
                ExternalRouteCandidate(
                    id = "bt_$idSuffix",
                    name = btName,
                    connectionTypeIndex = CONNECTION_TYPE_BLUETOOTH,
                    categoryIndex = categoryIndex,
                    priority = priority,
                    brand = null,
                    model = btName
                )
            }
            isWiredHeadsetOrHeadphonesType(type) -> {
                val productName = info.productName?.toString()?.trim().orEmpty()
                val displayName = if (
                    productName.isNotEmpty() &&
                    !productName.equals(Build.MODEL, ignoreCase = true)
                ) {
                    productName
                } else {
                    when (type) {
                        AudioDeviceInfo.TYPE_USB_HEADSET -> "USB headphones"
                        AudioDeviceInfo.TYPE_WIRED_HEADSET -> "Wired headset"
                        else -> "Wired headphones"
                    }
                }
                val priority = when (type) {
                    AudioDeviceInfo.TYPE_USB_HEADSET -> 420
                    AudioDeviceInfo.TYPE_WIRED_HEADSET -> 410
                    else -> 400
                }
                ExternalRouteCandidate(
                    id = "wired_${type}_${info.id}",
                    name = displayName,
                    connectionTypeIndex = CONNECTION_TYPE_WIRED,
                    categoryIndex = CATEGORY_HEADPHONES,
                    priority = priority,
                    brand = null,
                    model = displayName
                )
            }
            isWiredLineOrUsbSpeakerType(type) -> {
                val productName = info.productName?.toString()?.trim().orEmpty()
                val displayName = if (
                    productName.isNotEmpty() &&
                    !productName.equals(Build.MODEL, ignoreCase = true)
                ) {
                    productName
                } else {
                    when (type) {
                        AudioDeviceInfo.TYPE_USB_DEVICE,
                        AudioDeviceInfo.TYPE_USB_ACCESSORY -> "USB audio output"
                        AudioDeviceInfo.TYPE_HDMI,
                        AudioDeviceInfo.TYPE_HDMI_ARC -> "HDMI audio output"
                        else -> "Line out"
                    }
                }
                ExternalRouteCandidate(
                    id = "wired_${type}_${info.id}",
                    name = displayName,
                    connectionTypeIndex = CONNECTION_TYPE_WIRED,
                    categoryIndex = CATEGORY_SPEAKER,
                    priority = 350,
                    brand = null,
                    model = displayName
                )
            }
            else -> null
        }
    }

    private fun isBluetoothOutputType(type: Int): Boolean {
        if (type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP) return true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (
                type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                type == AudioDeviceInfo.TYPE_BLE_SPEAKER
            ) {
                return true
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (type == AudioDeviceInfo.TYPE_BLE_BROADCAST) {
                return true
            }
        }
        return false
    }

    private fun isWiredHeadsetOrHeadphonesType(type: Int): Boolean {
        return type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
            type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
            type == AudioDeviceInfo.TYPE_USB_HEADSET
    }

    private fun isWiredLineOrUsbSpeakerType(type: Int): Boolean {
        if (
            type == AudioDeviceInfo.TYPE_USB_DEVICE ||
            type == AudioDeviceInfo.TYPE_USB_ACCESSORY ||
            type == AudioDeviceInfo.TYPE_LINE_ANALOG ||
            type == AudioDeviceInfo.TYPE_LINE_DIGITAL ||
            type == AudioDeviceInfo.TYPE_HDMI ||
            type == AudioDeviceInfo.TYPE_HDMI_ARC
        ) {
            return true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (type == AudioDeviceInfo.TYPE_HDMI_EARC) {
                return true
            }
        }
        return false
    }

    private fun resolveBluetoothDevice(
        btAdapter: BluetoothAdapter?,
        address: String,
        hasBtConnect: Boolean
    ): BluetoothDevice? {
        if (!hasBtConnect || btAdapter == null || address.isEmpty()) return null
        return try {
            if (BluetoothAdapter.checkBluetoothAddress(address)) {
                btAdapter.getRemoteDevice(address)
            } else {
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to resolve remote BluetoothDevice for address: ${e.message}")
            null
        }
    }

    @SuppressLint("MissingPermission")
    private fun resolveBluetoothDeviceDisplayName(
        btDevice: BluetoothDevice?,
        fallbackProductName: String,
        hasBtConnect: Boolean
    ): String {
        if (hasBtConnect && btDevice != null) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    val alias = btDevice.alias?.trim()
                    if (!alias.isNullOrEmpty()) {
                        return alias
                    }
                }
                val name = btDevice.name?.trim()
                if (!name.isNullOrEmpty()) {
                    return name
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "SecurityException reading BluetoothDevice alias/name: ${e.message}")
            } catch (e: Exception) {
                Log.w(TAG, "Error reading BluetoothDevice alias/name: ${e.message}")
            }
        }
        if (
            fallbackProductName.isNotEmpty() &&
            !fallbackProductName.equals(Build.MODEL, ignoreCase = true)
        ) {
            return fallbackProductName
        }
        return "Bluetooth Audio"
    }

    @SuppressLint("MissingPermission")
    private fun classifyBluetoothCategory(
        audioDeviceType: Int,
        btDevice: BluetoothDevice?,
        displayName: String,
        hasBtConnect: Boolean
    ): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (audioDeviceType == AudioDeviceInfo.TYPE_BLE_SPEAKER) {
                return CATEGORY_SPEAKER
            }
            if (audioDeviceType == AudioDeviceInfo.TYPE_BLE_HEADSET) {
                return CATEGORY_HEADPHONES
            }
        }

        val lowerName = displayName.lowercase()
        if (
            lowerName.contains("frames") ||
            lowerName.contains("glasses") ||
            lowerName.contains("ray-ban")
        ) {
            return CATEGORY_GLASSES
        }
        if (lowerName.contains("watch")) {
            return CATEGORY_WEARABLE
        }

        if (hasBtConnect && btDevice != null) {
            try {
                val btClass: BluetoothClass? = btDevice.bluetoothClass
                if (btClass != null) {
                    when (btClass.deviceClass) {
                        BluetoothClass.Device.AUDIO_VIDEO_CAR_AUDIO -> return CATEGORY_CAR
                        BluetoothClass.Device.AUDIO_VIDEO_LOUDSPEAKER,
                        BluetoothClass.Device.AUDIO_VIDEO_PORTABLE_AUDIO,
                        BluetoothClass.Device.AUDIO_VIDEO_HIFI_AUDIO -> return CATEGORY_SPEAKER
                        BluetoothClass.Device.AUDIO_VIDEO_WEARABLE_HEADSET,
                        BluetoothClass.Device.AUDIO_VIDEO_HEADPHONES -> return CATEGORY_HEADPHONES
                    }
                    if (btClass.majorDeviceClass == BluetoothClass.Device.Major.WEARABLE) {
                        return CATEGORY_WEARABLE
                    }
                }
            } catch (e: SecurityException) {
                Log.w(TAG, "SecurityException reading BluetoothDevice.bluetoothClass: ${e.message}")
            } catch (e: Exception) {
                Log.w(TAG, "Error reading BluetoothDevice.bluetoothClass: ${e.message}")
            }
        }

        return when {
            lowerName.contains("car") ||
                lowerName.contains("auto") ||
                lowerName.contains("handsfree") -> CATEGORY_CAR
            lowerName.contains("speaker") ||
                lowerName.contains("soundbar") ||
                lowerName.contains("boombox") ||
                lowerName.contains("homepod") ||
                lowerName.contains("echo") ||
                lowerName.contains("roam") ||
                lowerName.contains("move") -> CATEGORY_SPEAKER
            else -> CATEGORY_HEADPHONES
        }
    }

    /**
     * Launches the Android System UI Media Output Switcher (`LAUNCH_MEDIA_OUTPUT_DIALOG` with
     * `package_name` extra), falling back to `Settings.ACTION_BLUETOOTH_SETTINGS` on OEM ROMs
     * and Android 9-10 (API 28-29).
     */
    private fun openSystemOutputSwitcherInternal(): Boolean {
        val pkgName = context.packageName
        try {
            val dialogActivityIntent = Intent(ACTION_LAUNCH_MEDIA_OUTPUT_DIALOG).apply {
                setPackage(SYSTEM_UI_PACKAGE)
                putExtra(EXTRA_PACKAGE_NAME, pkgName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(dialogActivityIntent)
            Log.i(TAG, "Launched SystemUI media output switcher activity for $pkgName")
            return true
        } catch (activityErr: Exception) {
            Log.w(
                TAG,
                "LAUNCH_MEDIA_OUTPUT_DIALOG startActivity unavailable (${activityErr.message}); trying broadcast/Bluetooth fallback"
            )
            try {
                val broadcastIntent = Intent(ACTION_LAUNCH_MEDIA_OUTPUT_DIALOG).apply {
                    setPackage(SYSTEM_UI_PACKAGE)
                    putExtra(EXTRA_PACKAGE_NAME, pkgName)
                }
                val receivers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.packageManager.queryBroadcastReceivers(
                        broadcastIntent,
                        PackageManager.ResolveInfoFlags.of(0)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.queryBroadcastReceivers(broadcastIntent, 0)
                }
                if (receivers.isNotEmpty()) {
                    context.sendBroadcast(broadcastIntent)
                    Log.i(TAG, "Dispatched LAUNCH_MEDIA_OUTPUT_DIALOG broadcast to SystemUI for $pkgName")
                    return true
                }
            } catch (broadcastErr: Exception) {
                Log.w(TAG, "LAUNCH_MEDIA_OUTPUT_DIALOG broadcast resolution failed: ${broadcastErr.message}")
            }

            return try {
                val btSettingsIntent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(btSettingsIntent)
                Log.i(TAG, "Opened Settings.ACTION_BLUETOOTH_SETTINGS fallback")
                true
            } catch (fallbackErr: Exception) {
                Log.e(
                    TAG,
                    "Failed to open Settings.ACTION_BLUETOOTH_SETTINGS fallback: ${fallbackErr.message}",
                    fallbackErr
                )
                false
            }
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
}
