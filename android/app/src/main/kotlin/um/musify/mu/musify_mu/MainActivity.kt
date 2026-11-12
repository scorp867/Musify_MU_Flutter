package um.musify.mu.musify_mu

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterFragmentActivity
import um.musify.mu.musify_mu.vault.VaultHardwareKeyStoreBridge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

object NativeDrmBridge {
    private val drmManager = MusifyDrmManager()

    @JvmStatic
    fun acquireSession(pssh: ByteArray, licenseUrl: String, authHeader: String?): ByteArray? {
        return drmManager.acquireStreamingSession(pssh, licenseUrl, authHeader)
    }

    @JvmStatic
    fun closeSession(sessionId: ByteArray) {
        drmManager.closeSession(sessionId)
    }

    @JvmStatic
    fun closeActiveSession() {
        drmManager.closeActiveSession()
    }
}

object NativeHeadDownloader {
    private const val TAG = "NativeHeadDownloader"
    private const val HEAD_CDN_BASE = "https://heads-fa-tls13.spotifycdn.com/head/"
    private const val MIN_HEAD_FILE_SIZE = 512L
    private const val INITIAL_CHUNK_WAIT_BYTES = 8192L
    private const val CONNECT_TIMEOUT_MS = 5000
    private const val READ_TIMEOUT_MS = 10000

    private val executor = Executors.newFixedThreadPool(4)
    private val activeLocks = java.util.concurrent.ConcurrentHashMap<String, Any>()

    @JvmStatic
    fun downloadHeadFile(fileIdHex: String, targetFilePath: String): Boolean {
        return startStreamingHeadFile(fileIdHex, targetFilePath)
    }

    @JvmStatic
    fun startStreamingHeadFile(fileIdHex: String, targetFilePath: String): Boolean {
        try {
            val targetFile = java.io.File(targetFilePath)
            if (targetFile.exists() && targetFile.length() >= MIN_HEAD_FILE_SIZE) {
                android.util.Log.i(TAG, "Head file cache hit: $targetFilePath (size=${targetFile.length()})")
                return true
            }

            targetFile.parentFile?.mkdirs()
            val partFile = java.io.File("${targetFilePath}.part")

            val readyLatch = java.util.concurrent.CountDownLatch(1)
            val streamFailed = java.util.concurrent.atomic.AtomicBoolean(false)
            val lock = activeLocks.computeIfAbsent(fileIdHex) { Any() }

            executor.submit {
                synchronized(lock) {
                    if (targetFile.exists() && targetFile.length() >= MIN_HEAD_FILE_SIZE) {
                        readyLatch.countDown()
                        return@submit
                    }

                    var conn: java.net.HttpURLConnection? = null
                    try {
                        val url = java.net.URL("$HEAD_CDN_BASE$fileIdHex")
                        android.util.Log.i(TAG, "Streaming head file from $url to $targetFilePath")
                        conn = url.openConnection() as java.net.HttpURLConnection
                        conn.requestMethod = "GET"
                        conn.connectTimeout = CONNECT_TIMEOUT_MS
                        conn.readTimeout = READ_TIMEOUT_MS
                        conn.setRequestProperty("User-Agent", "Spotify/8.9.18 Android/34")
                        conn.setRequestProperty("Accept-Encoding", "identity")

                        val responseCode = conn.responseCode
                        if (responseCode !in 200..299) {
                            android.util.Log.e(TAG, "CDN returned HTTP code: $responseCode for $fileIdHex")
                            streamFailed.set(true)
                            readyLatch.countDown()
                            return@submit
                        }

                        val expectedLength = conn.contentLengthLong

                        partFile.outputStream().use { output ->
                            conn.inputStream.use { input ->
                                val buffer = ByteArray(8192)
                                var bytesRead: Int
                                var totalWritten = 0L

                                while (input.read(buffer).also { bytesRead = it } != -1) {
                                    output.write(buffer, 0, bytesRead)
                                    output.flush()
                                    totalWritten += bytesRead

                                    // Signal readiness as soon as initial chunk is written to disk for < 30ms TTFA
                                    if (totalWritten >= INITIAL_CHUNK_WAIT_BYTES || totalWritten >= MIN_HEAD_FILE_SIZE) {
                                        readyLatch.countDown()
                                    }
                                }
                                output.flush()
                            }
                        }

                        val finalLength = partFile.length()
                        val isValid = if (expectedLength > 0L) {
                            finalLength == expectedLength
                        } else {
                            finalLength >= MIN_HEAD_FILE_SIZE
                        }

                        if (isValid) {
                            if (targetFile.exists()) {
                                targetFile.delete()
                            }
                            try {
                                java.nio.file.Files.move(
                                    partFile.toPath(),
                                    targetFile.toPath(),
                                    java.nio.file.StandardCopyOption.REPLACE_EXISTING,
                                    java.nio.file.StandardCopyOption.ATOMIC_MOVE
                                )
                            } catch (_: Exception) {
                                partFile.renameTo(targetFile)
                            }
                            android.util.Log.i(TAG, "Head file stream complete and cached: $targetFilePath (size=$finalLength)")
                        } else {
                            android.util.Log.e(TAG, "Downloaded stream length invalid: $finalLength (expected $expectedLength)")
                            partFile.delete()
                            streamFailed.set(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e(TAG, "Exception streaming head file for $fileIdHex: ${e.message}", e)
                        streamFailed.set(true)
                        if (partFile.exists()) {
                            partFile.delete()
                        }
                    } finally {
                        readyLatch.countDown()
                        try {
                            conn?.disconnect()
                        } catch (_: Exception) {}
                    }
                }
            }

            // Await readiness: unblocks caller as soon as the first 8 KB hits disk
            val ready = readyLatch.await(4, TimeUnit.SECONDS)
            return ready && !streamFailed.get()
        } catch (e: Exception) {
            android.util.Log.e(TAG, "startStreamingHeadFile execution failed for $fileIdHex", e)
            return false
        }
    }
}

class MainActivity : FlutterFragmentActivity() {
    private var vaultBridge: VaultHardwareKeyStoreBridge? = null
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
    private val DRM_CHANNEL = "com.musify.mu/drm"
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
        } catch (_: Throwable) {}
        super.configureFlutterEngine(flutterEngine)

        // Register Vault Hardware KeyStore Bridge
        val bridge = VaultHardwareKeyStoreBridge(this)
        bridge.register(flutterEngine.dartExecutor.binaryMessenger)
        vaultBridge = bridge

        // Cookie method channel - reads HttpOnly cookies via Android's native CookieManager.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, COOKIE_CHANNEL)
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

        // DRM method channel - facilitates Widevine license acquisition from Dart if desired.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DRM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireDrmSession" -> {
                        val pssh = call.argument<ByteArray>("pssh")
                        val licenseUrl = call.argument<String>("licenseUrl")
                        val authHeader = call.argument<String>("authHeader")

                        if (pssh != null && licenseUrl != null) {
                            thread {
                                val sessionId = NativeDrmBridge.acquireSession(pssh, licenseUrl, authHeader)
                                Handler(Looper.getMainLooper()).post {
                                    if (sessionId != null) {
                                        result.success(sessionId)
                                    } else {
                                        result.error("DRM_FAILED", "Failed to acquire Widevine session after retries", null)
                                    }
                                }
                            }
                        } else {
                            result.error("INVALID_ARGS", "pssh and licenseUrl are required", null)
                        }
                    }
                    "closeDrmSession" -> {
                        val sessionId = call.argument<ByteArray>("sessionId")
                        if (sessionId != null) {
                            NativeDrmBridge.closeSession(sessionId)
                        } else {
                            NativeDrmBridge.closeActiveSession()
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Register Screen Privacy Method Channel
        val privacyChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_PRIVACY_CHANNEL)
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

        val artworkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCAL_ARTWORK_CHANNEL)
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
                                } catch (_: Exception) {}
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
        localArtworkChannel = artworkChannel

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, OBSERVER_CHANNEL).setStreamHandler(
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
