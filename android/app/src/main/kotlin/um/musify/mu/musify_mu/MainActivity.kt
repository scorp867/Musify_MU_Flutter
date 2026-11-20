package um.musify.mu.musify_mu

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import um.musify.mu.musify_mu.connect.AudioRouteMonitor
import um.musify.mu.musify_mu.connect.ConnectNsdDiscovery
import um.musify.mu.musify_mu.connect.DeviceEnvironmentBridge
import um.musify.mu.musify_mu.connect.SystemVolumeBridge
import um.musify.mu.musify_mu.vault.VaultHardwareKeyStoreBridge
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private var vaultBridge: VaultHardwareKeyStoreBridge? = null
    private var deviceEnvironmentBridge: DeviceEnvironmentBridge? = null
    private var audioRouteMonitor: AudioRouteMonitor? = null
    private var systemVolumeBridge: SystemVolumeBridge? = null
    private var connectNsdDiscovery: ConnectNsdDiscovery? = null

    private var screenPrivacyChannel: MethodChannel? = null
    private var localArtworkChannel: MethodChannel? = null
    private val artworkExecutor = Executors.newFixedThreadPool(2)
    private val artworkCacheLock = Any()
    private val artworkInFlight = mutableMapOf<String, MutableList<MethodChannel.Result>>()
    private val artworkCache = object : android.util.LruCache<String, ByteArray>(8 * 1024 * 1024) {
        override fun sizeOf(key: String, value: ByteArray): Int = value.size.coerceAtLeast(1)
    }

    companion object {
        init {
            try {
                System.loadLibrary("musify_audio")
                android.util.Log.i("MainActivity", "Successfully loaded libmusify_audio.so via System.loadLibrary")
            } catch (e: UnsatisfiedLinkError) {
                android.util.Log.e("MainActivity", "Failed to load libmusify_audio.so", e)
            }
        }
    }

    private val OBSERVER_CHANNEL = "musify_mu/mediastore_observer"
    private val COOKIE_CHANNEL = "com.musify.mu/cookies"
    private val SCREEN_PRIVACY_CHANNEL = "um.musify.mu/screen_privacy"
    private val LOCAL_ARTWORK_CHANNEL = "um.musify.mu/local_artwork"

    private var eventSink: EventChannel.EventSink? = null
    private var observer: ContentObserver? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        androidx.core.view.WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        try {
            System.loadLibrary("musify_audio")
        } catch (e: Throwable) {
            android.util.Log.w("MainActivity", "System.loadLibrary(musify_audio) check in configureFlutterEngine: ${e.message}")
        }
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Register Vault Hardware KeyStore Bridge
        vaultBridge?.detach()
        val bridge = VaultHardwareKeyStoreBridge(this)
        bridge.register(messenger)
        vaultBridge = bridge

        // Register Spotify Connect Platform Bridges
        detachConnectBridges()

        val envBridge = DeviceEnvironmentBridge(applicationContext)
        envBridge.register(messenger)
        deviceEnvironmentBridge = envBridge

        val routeMonitor = AudioRouteMonitor(applicationContext)
        routeMonitor.register(messenger)
        audioRouteMonitor = routeMonitor

        val volumeBridge = SystemVolumeBridge(applicationContext)
        volumeBridge.register(messenger)
        systemVolumeBridge = volumeBridge

        val nsdBridge = ConnectNsdDiscovery(applicationContext)
        nsdBridge.register(messenger)
        connectNsdDiscovery = nsdBridge

        // Cookie method channel - reads HttpOnly cookies via Android's native CookieManager.
        MethodChannel(messenger, COOKIE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getCookies") {
                    val url = call.arguments as? String
                    if (url != null) {
                        try {
                            val cookieManager = CookieManager.getInstance()
                            val cookies = cookieManager.getCookie(url)
                            result.success(cookies)
                        } catch (e: Exception) {
                            result.error("COOKIE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL argument is required", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // Register Screen Privacy Method Channel
        val privacyChannel = MethodChannel(messenger, SCREEN_PRIVACY_CHANNEL)
        privacyChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureFlag" -> setWindowSecureFlag(true, result)
                "disableSecureFlag" -> setWindowSecureFlag(false, result)
                "setSecureFlag" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled != null) {
                        setWindowSecureFlag(enabled, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Missing 'enabled' parameter in setSecureFlag", null)
                    }
                }
                "isSecureFlagEngaged" -> {
                    runOnUiThread {
                        try {
                            if (isFinishing || isDestroyed) {
                                result.error("ACTIVITY_DESTROYED", "Cannot inspect window on finishing/destroyed Activity", null)
                                return@runOnUiThread
                            }
                            val win = window
                            if (win == null) {
                                result.error("WINDOW_NULL", "Window reference is null", null)
                                return@runOnUiThread
                            }
                            val flags = win.attributes.flags
                            val isSecure = (flags and android.view.WindowManager.LayoutParams.FLAG_SECURE) != 0
                            result.success(isSecure)
                        } catch (e: Exception) {
                            result.error("QUERY_ERROR", "Failed to query FLAG_SECURE: ${e.message}", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        screenPrivacyChannel = privacyChannel

        val artworkChannel = MethodChannel(messenger, LOCAL_ARTWORK_CHANNEL)
        artworkChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "extractEmbeddedArtwork" -> {
                    val rawPath = call.argument<String>("filePath")?.trim()
                    if (rawPath.isNullOrEmpty()) {
                        result.error("INVALID_ARGUMENT", "Missing 'filePath' parameter", null)
                        return@setMethodCallHandler
                    }
                    val maxDimension = (call.argument<Int>("maxDimension") ?: 720).coerceIn(64, 1024)
                    val resolvedPath = if (rawPath.startsWith("file://")) {
                        Uri.parse(rawPath).path ?: rawPath.removePrefix("file://")
                    } else {
                        rawPath
                    }
                    val cacheKey = "$resolvedPath#$maxDimension"
                    val cachedBytes: ByteArray?
                    val isLeader: Boolean
                    synchronized(artworkCacheLock) {
                        cachedBytes = artworkCache.get(cacheKey)
                        if (cachedBytes != null) {
                            isLeader = false
                        } else {
                            val existingWaiters = artworkInFlight[cacheKey]
                            if (existingWaiters != null) {
                                existingWaiters.add(result)
                                isLeader = false
                            } else {
                                artworkInFlight[cacheKey] = mutableListOf(result)
                                isLeader = true
                            }
                        }
                    }
                    if (cachedBytes != null) {
                        result.success(cachedBytes)
                        return@setMethodCallHandler
                    }
                    if (!isLeader) {
                        return@setMethodCallHandler
                    }
                    try {
                        artworkExecutor.submit {
                            val retriever = android.media.MediaMetadataRetriever()
                            val mainHandler = Handler(Looper.getMainLooper())
                            var outBytes: ByteArray? = null
                            var errorMessage: String? = null
                            try {
                                val file = java.io.File(resolvedPath)
                                if (file.exists() && file.isFile) {
                                    retriever.setDataSource(resolvedPath)
                                    val rawPicture = retriever.embeddedPicture
                                    if (rawPicture != null && rawPicture.isNotEmpty()) {
                                        val processed = downsampleArtwork(rawPicture, maxDimension)
                                        synchronized(artworkCacheLock) {
                                            artworkCache.put(cacheKey, processed)
                                        }
                                        outBytes = processed
                                    }
                                }
                            } catch (e: Exception) {
                                android.util.Log.w("MainActivity", "Failed to extract embedded artwork for $resolvedPath: ${e.message}")
                                errorMessage = e.message ?: "Artwork extraction error"
                            } finally {
                                try {
                                    retriever.release()
                                } catch (e: Exception) {
                                    android.util.Log.w("MainActivity", "MediaMetadataRetriever.release error: ${e.message}")
                                }
                            }
                            val waiters: List<MethodChannel.Result> = synchronized(artworkCacheLock) {
                                artworkInFlight.remove(cacheKey)?.toList() ?: emptyList()
                            }
                            mainHandler.post {
                                for (waiter in waiters) {
                                    if (errorMessage != null) {
                                        waiter.error("ARTWORK_EXTRACT_ERROR", errorMessage, null)
                                    } else {
                                        waiter.success(outBytes)
                                    }
                                }
                            }
                        }
                    } catch (e: java.util.concurrent.RejectedExecutionException) {
                        val waiters: List<MethodChannel.Result> = synchronized(artworkCacheLock) {
                            artworkInFlight.remove(cacheKey)?.toList() ?: emptyList()
                        }
                        for (waiter in waiters) {
                            waiter.success(null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        localArtworkChannel = artworkChannel

        EventChannel(messenger, OBSERVER_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerObserver()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterObserver()
                }
            }
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        detachConnectBridges()
        vaultBridge?.detach()
        vaultBridge = null
        screenPrivacyChannel?.setMethodCallHandler(null)
        screenPrivacyChannel = null
        localArtworkChannel?.setMethodCallHandler(null)
        localArtworkChannel = null
        unregisterObserver()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun detachConnectBridges() {
        deviceEnvironmentBridge?.detach()
        deviceEnvironmentBridge = null

        audioRouteMonitor?.detach()
        audioRouteMonitor = null

        systemVolumeBridge?.detach()
        systemVolumeBridge = null

        connectNsdDiscovery?.detach()
        connectNsdDiscovery = null
    }

    private fun setWindowSecureFlag(enable: Boolean, result: MethodChannel.Result) {
        runOnUiThread {
            try {
                if (isFinishing || isDestroyed) {
                    result.error("ACTIVITY_DESTROYED", "Cannot mutate window flags on finishing/destroyed Activity", null)
                    return@runOnUiThread
                }
                val win = window
                if (win == null) {
                    result.error("WINDOW_NULL", "Window reference is null on current Activity", null)
                    return@runOnUiThread
                }
                if (enable) {
                    win.addFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    android.util.Log.i("MainActivity", "Engaged WindowManager.LayoutParams.FLAG_SECURE")
                } else {
                    win.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                    android.util.Log.i("MainActivity", "Released WindowManager.LayoutParams.FLAG_SECURE")
                }
                result.success(true)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Failed to mutate FLAG_SECURE: ${e.message}", e)
                result.error("WINDOW_FLAG_ERROR", "Failed to update FLAG_SECURE: ${e.message}", null)
            }
        }
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) {
            synchronized(artworkCacheLock) {
                artworkCache.evictAll()
            }
        }
    }

    private fun downsampleArtwork(rawBytes: ByteArray, maxDimension: Int): ByteArray {
        val bounds = android.graphics.BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        android.graphics.BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, bounds)
        val srcW = bounds.outWidth
        val srcH = bounds.outHeight
        if (srcW <= 0 || srcH <= 0) {
            return rawBytes
        }
        val largestDim = maxOf(srcW, srcH)
        if (largestDim <= maxDimension && rawBytes.size <= 256 * 1024) {
            return rawBytes
        }
        var inSampleSize = 1
        while ((srcW / inSampleSize) >= maxDimension * 2 && (srcH / inSampleSize) >= maxDimension * 2) {
            inSampleSize *= 2
        }
        val decodeOpts = android.graphics.BitmapFactory.Options().apply {
            this.inSampleSize = inSampleSize
            inPreferredConfig = android.graphics.Bitmap.Config.ARGB_8888
        }
        val sampled = android.graphics.BitmapFactory.decodeByteArray(rawBytes, 0, rawBytes.size, decodeOpts)
            ?: return rawBytes
        val currentMax = maxOf(sampled.width, sampled.height)
        val finalBitmap = if (currentMax > maxDimension) {
            val scale = maxDimension.toFloat() / currentMax.toFloat()
            val targetW = maxOf(1, (sampled.width * scale).toInt())
            val targetH = maxOf(1, (sampled.height * scale).toInt())
            android.graphics.Bitmap.createScaledBitmap(sampled, targetW, targetH, true).also {
                if (it !== sampled) sampled.recycle()
            }
        } else {
            sampled
        }
        return try {
            val out = java.io.ByteArrayOutputStream()
            val format = if (finalBitmap.hasAlpha()) {
                android.graphics.Bitmap.CompressFormat.PNG
            } else {
                android.graphics.Bitmap.CompressFormat.JPEG
            }
            finalBitmap.compress(format, 88, out)
            out.toByteArray()
        } finally {
            finalBitmap.recycle()
        }
    }

    override fun onDestroy() {
        detachConnectBridges()
        localArtworkChannel?.setMethodCallHandler(null)
        localArtworkChannel = null
        synchronized(artworkCacheLock) {
            artworkInFlight.clear()
            artworkCache.evictAll()
        }
        artworkExecutor.shutdownNow()
        screenPrivacyChannel?.setMethodCallHandler(null)
        screenPrivacyChannel = null
        vaultBridge?.detach()
        vaultBridge = null
        unregisterObserver()
        super.onDestroy()
    }

    private fun registerObserver() {
        if (observer == null) {
            val newObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    eventSink?.success("changed")
                }
            }
            observer = newObserver
            contentResolver.registerContentObserver(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                true,
                newObserver
            )
        }
    }

    private fun unregisterObserver() {
        observer?.let {
            contentResolver.unregisterContentObserver(it)
            observer = null
        }
    }
}
