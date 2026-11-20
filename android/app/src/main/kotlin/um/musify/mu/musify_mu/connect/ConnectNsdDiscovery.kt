package um.musify.mu.musify_mu.connect

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address
import java.net.InetAddress
import java.nio.charset.StandardCharsets

/**
 * Local Network mDNS / Zeroconf (`_spotify-connect._tcp.`) Discovery Bridge for Spotify Connect.
 *
 * Replicates Spotify Android's local network discovery and multicast management:
 * - `NsdManager` DNS-SD service discovery lifecycle (`p199p/a54.java:70-72`).
 * - Reference-counted `WifiManager.MulticastLock` management (`p199p/jhe1.java`).
 * - Foreground and local-network permission-gated discovery feeding Zeroconf `getInfo` and
 *   `PUT connect-state/v1/update_local_devices` (`p199p/asq.java:74-173`).
 * - Resolves host IP (preferring IPv4), port, and TXT attributes (`CPath`, `VERSION`, `STACK`)
 *   safely across both API >= 34 (`registerServiceInfoCallback`) and API < 34
 *   (serialized FIFO `resolveService` queue avoiding `FAILURE_ALREADY_ACTIVE`).
 */
class ConnectNsdDiscovery(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "[CONNECT-KOTLIN]"
        const val CONTROL_CHANNEL_NAME = "um.musify.mu/connect/nsd_control"
        const val EVENTS_CHANNEL_NAME = "um.musify.mu/connect/nsd_events"

        private const val SPOTIFY_CONNECT_SERVICE_TYPE = "_spotify-connect._tcp."
        private const val MULTICAST_LOCK_TAG = "musify_connect_mdns_lock"
        private const val DEFAULT_CPATH = "/"
        private const val DEFAULT_VERSION = "1.0"
        private const val MAX_RESOLVE_RETRIES = 2
    }

    private data class ResolvedConnectService(
        val serviceName: String,
        val host: String,
        val port: Int,
        val cPath: String,
        val version: String,
        val stack: String?
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "serviceName" to serviceName,
            "host" to host,
            "port" to port,
            "cPath" to cPath,
            "version" to version,
            "stack" to stack
        )
    }

    private data class PendingResolveEntry(
        val serviceInfo: NsdServiceInfo,
        val attempt: Int
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private val mainExecutor = ContextCompat.getMainExecutor(context)
    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as? NsdManager
    private val wifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    private var controlChannel: MethodChannel? = null
    private var eventsChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private val stateLock = Any()
    private var multicastLock: WifiManager.MulticastLock? = null
    private var isMulticastLockHeld = false
    private var activeDiscoveryListener: NsdManager.DiscoveryListener? = null
    private var isDiscoveryActive = false

    private val resolvedServices = LinkedHashMap<String, ResolvedConnectService>()
    private val pendingResolveQueue = ArrayDeque<PendingResolveEntry>()
    private var isResolveInFlight = false

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private val api34Callbacks = LinkedHashMap<String, NsdManager.ServiceInfoCallback>()

    fun register(messenger: BinaryMessenger) {
        controlChannel = MethodChannel(messenger, CONTROL_CHANNEL_NAME).apply {
            setMethodCallHandler(this@ConnectNsdDiscovery)
        }
        eventsChannel = EventChannel(messenger, EVENTS_CHANNEL_NAME).apply {
            setStreamHandler(this@ConnectNsdDiscovery)
        }
        Log.i(TAG, "ConnectNsdDiscovery registered on $CONTROL_CHANNEL_NAME and $EVENTS_CHANNEL_NAME")
    }

    fun detach() {
        stopDiscoveryInternal(emitSnapshot = false)
        eventSink = null
        controlChannel?.setMethodCallHandler(null)
        controlChannel = null
        eventsChannel?.setStreamHandler(null)
        eventsChannel = null
        Log.i(TAG, "ConnectNsdDiscovery detached")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> {
                try {
                    val started = startDiscoveryInternal()
                    result.success(started)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start NSD discovery: ${e.message}", e)
                    result.error(
                        "NSD_START_ERROR",
                        "Failed to start NSD discovery: ${e.message}",
                        null
                    )
                }
            }
            "stopDiscovery" -> {
                try {
                    stopDiscoveryInternal(emitSnapshot = true)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to stop NSD discovery: ${e.message}", e)
                    result.error(
                        "NSD_STOP_ERROR",
                        "Failed to stop NSD discovery: ${e.message}",
                        null
                    )
                }
            }
            "getDiscoveredServices" -> {
                try {
                    result.success(snapshotDiscoveredServices())
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to snapshot NSD discovered services: ${e.message}", e)
                    result.error(
                        "NSD_QUERY_ERROR",
                        "Failed to query discovered services: ${e.message}",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        events?.success(snapshotDiscoveredServices())
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun startDiscoveryInternal(): Boolean {
        val manager = nsdManager ?: run {
            Log.w(TAG, "NsdManager system service is unavailable")
            return false
        }

        synchronized(stateLock) {
            if (isDiscoveryActive && activeDiscoveryListener != null) {
                emitDiscoveredServicesOnMain()
                return true
            }
            acquireMulticastLockLocked()

            val listener = createDiscoveryListener()
            return try {
                manager.discoverServices(
                    SPOTIFY_CONNECT_SERVICE_TYPE,
                    NsdManager.PROTOCOL_DNS_SD,
                    listener
                )
                activeDiscoveryListener = listener
                isDiscoveryActive = true
                Log.i(TAG, "Started NSD discovery for $SPOTIFY_CONNECT_SERVICE_TYPE")
                true
            } catch (e: Exception) {
                Log.e(TAG, "NsdManager.discoverServices threw exception: ${e.message}", e)
                releaseMulticastLockLocked()
                false
            }
        }
    }

    private fun stopDiscoveryInternal(emitSnapshot: Boolean) {
        val manager = nsdManager
        synchronized(stateLock) {
            val listener = activeDiscoveryListener
            activeDiscoveryListener = null
            isDiscoveryActive = false

            if (listener != null && manager != null) {
                try {
                    manager.stopServiceDiscovery(listener)
                } catch (e: Exception) {
                    Log.w(TAG, "NsdManager.stopServiceDiscovery threw: ${e.message}")
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && manager != null) {
                unregisterAllApi34CallbacksLocked(manager)
            }

            pendingResolveQueue.clear()
            isResolveInFlight = false
            resolvedServices.clear()
            releaseMulticastLockLocked()
        }

        if (emitSnapshot) {
            emitDiscoveredServicesOnMain()
        }
    }

    private fun createDiscoveryListener(): NsdManager.DiscoveryListener {
        return object : NsdManager.DiscoveryListener {
            override fun onStartDiscoveryFailed(serviceType: String?, errorCode: Int) {
                Log.w(TAG, "NSD onStartDiscoveryFailed ($serviceType): errorCode=$errorCode")
                synchronized(stateLock) {
                    isDiscoveryActive = false
                    activeDiscoveryListener = null
                    releaseMulticastLockLocked()
                }
            }

            override fun onStopDiscoveryFailed(serviceType: String?, errorCode: Int) {
                Log.w(TAG, "NSD onStopDiscoveryFailed ($serviceType): errorCode=$errorCode")
            }

            override fun onDiscoveryStarted(serviceType: String?) {
                Log.i(TAG, "NSD discovery active for $serviceType")
            }

            override fun onDiscoveryStopped(serviceType: String?) {
                Log.i(TAG, "NSD discovery stopped for $serviceType")
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo?) {
                if (serviceInfo == null) return
                val rawType = serviceInfo.serviceType?.trim().orEmpty()
                if (!rawType.contains("_spotify-connect._tcp", ignoreCase = true)) {
                    return
                }
                scheduleServiceResolution(serviceInfo)
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo?) {
                val lostName = serviceInfo?.serviceName?.trim()
                if (lostName.isNullOrEmpty()) return
                handleServiceLost(lostName)
            }
        }
    }

    private fun scheduleServiceResolution(serviceInfo: NsdServiceInfo) {
        val manager = nsdManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            if (registerApi34ServiceCallback(manager, serviceInfo)) {
                return
            }
        }

        synchronized(stateLock) {
            if (!isDiscoveryActive) return
            val name = serviceInfo.serviceName?.trim().orEmpty()
            val alreadyQueued = pendingResolveQueue.any {
                it.serviceInfo.serviceName == name
            }
            if (!alreadyQueued) {
                pendingResolveQueue.addLast(PendingResolveEntry(serviceInfo, attempt = 1))
            }
            drainLegacyResolveQueueLocked(manager)
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun registerApi34ServiceCallback(
        manager: NsdManager,
        serviceInfo: NsdServiceInfo
    ): Boolean {
        val serviceName = serviceInfo.serviceName?.trim()
        if (serviceName.isNullOrEmpty()) return false

        synchronized(stateLock) {
            if (!isDiscoveryActive) return true
            if (api34Callbacks.containsKey(serviceName)) {
                return true
            }

            val callback = object : NsdManager.ServiceInfoCallback {
                override fun onServiceInfoCallbackRegistrationFailed(errorCode: Int) {
                    Log.w(
                        TAG,
                        "NSD registerServiceInfoCallback failed for $serviceName (code=$errorCode)"
                    )
                    synchronized(stateLock) {
                        api34Callbacks.remove(serviceName)
                    }
                }

                override fun onServiceUpdated(updatedInfo: NsdServiceInfo) {
                    handleServiceResolved(updatedInfo)
                }

                override fun onServiceLost() {
                    handleServiceLost(serviceName)
                }

                override fun onServiceInfoCallbackUnregistered() {
                    synchronized(stateLock) {
                        api34Callbacks.remove(serviceName)
                    }
                }
            }

            return try {
                manager.registerServiceInfoCallback(serviceInfo, mainExecutor, callback)
                api34Callbacks[serviceName] = callback
                true
            } catch (e: Exception) {
                Log.w(
                    TAG,
                    "registerServiceInfoCallback threw for $serviceName, falling back to queue: ${e.message}"
                )
                false
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun unregisterAllApi34CallbacksLocked(manager: NsdManager) {
        val callbacks = api34Callbacks.values.toList()
        api34Callbacks.clear()
        for (cb in callbacks) {
            try {
                manager.unregisterServiceInfoCallback(cb)
            } catch (e: Exception) {
                Log.w(TAG, "unregisterServiceInfoCallback threw: ${e.message}")
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun drainLegacyResolveQueueLocked(manager: NsdManager) {
        if (isResolveInFlight || !isDiscoveryActive) return
        val next = pendingResolveQueue.removeFirstOrNull() ?: return
        isResolveInFlight = true

        try {
            manager.resolveService(
                next.serviceInfo,
                object : NsdManager.ResolveListener {
                    override fun onResolveFailed(failedInfo: NsdServiceInfo?, errorCode: Int) {
                        synchronized(stateLock) {
                            isResolveInFlight = false
                            if (
                                errorCode == NsdManager.FAILURE_ALREADY_ACTIVE &&
                                next.attempt < MAX_RESOLVE_RETRIES &&
                                isDiscoveryActive
                            ) {
                                pendingResolveQueue.addLast(
                                    next.copy(attempt = next.attempt + 1)
                                )
                            } else {
                                Log.w(
                                    TAG,
                                    "NSD resolveService failed for ${failedInfo?.serviceName}: code=$errorCode"
                                )
                            }
                            drainLegacyResolveQueueLocked(manager)
                        }
                    }

                    override fun onServiceResolved(resolvedInfo: NsdServiceInfo?) {
                        if (resolvedInfo != null) {
                            handleServiceResolved(resolvedInfo)
                        }
                        synchronized(stateLock) {
                            isResolveInFlight = false
                            drainLegacyResolveQueueLocked(manager)
                        }
                    }
                }
            )
        } catch (e: Exception) {
            Log.w(TAG, "NsdManager.resolveService threw: ${e.message}")
            isResolveInFlight = false
            drainLegacyResolveQueueLocked(manager)
        }
    }

    private fun handleServiceResolved(info: NsdServiceInfo) {
        val serviceName = info.serviceName?.trim()
        if (serviceName.isNullOrEmpty()) return

        val port = info.port
        if (port <= 0) return

        val hostAddress = extractPreferredHostAddress(info)
        if (hostAddress.isNullOrEmpty()) return

        val attributes = info.attributes
        val rawCPath = extractTxtAttribute(attributes, "CPath")
        val normalizedCPath = when {
            rawCPath.isNullOrEmpty() -> DEFAULT_CPATH
            rawCPath.startsWith("/") -> rawCPath
            else -> "/$rawCPath"
        }
        val version = extractTxtAttribute(attributes, "VERSION")
            ?.takeIf { it.isNotEmpty() }
            ?: DEFAULT_VERSION
        val stack = extractTxtAttribute(attributes, "STACK")
            ?.takeIf { it.isNotEmpty() }

        val resolved = ResolvedConnectService(
            serviceName = serviceName,
            host = hostAddress,
            port = port,
            cPath = normalizedCPath,
            version = version,
            stack = stack
        )

        var changed = false
        synchronized(stateLock) {
            if (!isDiscoveryActive) return
            val previous = resolvedServices.put(serviceName, resolved)
            if (previous != resolved) {
                changed = true
            }
        }

        if (changed) {
            emitDiscoveredServicesOnMain()
        }
    }

    private fun handleServiceLost(serviceName: String) {
        var changed = false
        val manager = nsdManager
        synchronized(stateLock) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && manager != null) {
                val callback = api34Callbacks.remove(serviceName)
                if (callback != null) {
                    try {
                        manager.unregisterServiceInfoCallback(callback)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to unregister callback for lost service $serviceName: ${e.message}")
                    }
                }
            }
            if (resolvedServices.remove(serviceName) != null) {
                changed = true
            }
        }
        if (changed) {
            emitDiscoveredServicesOnMain()
        }
    }

    private fun extractPreferredHostAddress(info: NsdServiceInfo): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            try {
                val addresses: List<InetAddress> = info.hostAddresses
                if (addresses.isNotEmpty()) {
                    val ipv4 = addresses.firstOrNull { it is Inet4Address && !it.isLoopbackAddress }
                        ?: addresses.firstOrNull { it is Inet4Address }
                    val chosen = ipv4 ?: addresses.first()
                    val clean = sanitizeHostAddress(chosen.hostAddress)
                    if (!clean.isNullOrEmpty()) {
                        return clean
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to read NsdServiceInfo.hostAddresses: ${e.message}")
            }
        }

        @Suppress("DEPRECATION")
        val legacyHost = info.host?.hostAddress
        return sanitizeHostAddress(legacyHost)
    }

    private fun sanitizeHostAddress(rawHost: String?): String? {
        if (rawHost.isNullOrBlank()) return null
        val trimmed = rawHost.trim()
        val zoneSeparatorIndex = trimmed.indexOf('%')
        val withoutZone = if (zoneSeparatorIndex > 0) {
            trimmed.substring(0, zoneSeparatorIndex)
        } else {
            trimmed
        }
        return withoutZone.takeIf { it.isNotEmpty() }
    }

    private fun extractTxtAttribute(
        attributes: Map<String, ByteArray?>?,
        targetKey: String
    ): String? {
        if (attributes.isNullOrEmpty()) return null
        for ((key, valueBytes) in attributes) {
            if (key.equals(targetKey, ignoreCase = true)) {
                if (valueBytes == null || valueBytes.isEmpty()) return null
                return String(valueBytes, StandardCharsets.UTF_8).trim()
            }
        }
        return null
    }

    private fun acquireMulticastLockLocked() {
        if (isMulticastLockHeld) return
        try {
            val lock = multicastLock ?: wifiManager?.createMulticastLock(MULTICAST_LOCK_TAG)?.apply {
                setReferenceCounted(true)
            }
            multicastLock = lock
            if (lock != null && !lock.isHeld) {
                lock.acquire()
                isMulticastLockHeld = true
                Log.i(TAG, "Acquired WifiManager.MulticastLock ($MULTICAST_LOCK_TAG)")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire WifiManager.MulticastLock: ${e.message}")
        }
    }

    private fun releaseMulticastLockLocked() {
        if (!isMulticastLockHeld) return
        try {
            val lock = multicastLock
            if (lock != null && lock.isHeld) {
                lock.release()
                Log.i(TAG, "Released WifiManager.MulticastLock ($MULTICAST_LOCK_TAG)")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to release WifiManager.MulticastLock: ${e.message}")
        } finally {
            isMulticastLockHeld = false
        }
    }

    private fun snapshotDiscoveredServices(): List<Map<String, Any?>> {
        synchronized(stateLock) {
            return resolvedServices.values.map { it.toMap() }
        }
    }

    private fun emitDiscoveredServicesOnMain() {
        val snapshot = snapshotDiscoveredServices()
        mainHandler.post {
            eventSink?.success(snapshot)
        }
    }
}
