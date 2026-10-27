package um.musify.mu.musify_mu

import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
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
}

object NativeHeadDownloader {
    private const val TAG = "NativeHeadDownloader"
    private const val HEAD_CDN_BASE = "https://heads-fa-tls13.spotifycdn.com/head/"
    private const val MIN_HEAD_FILE_SIZE = 512L
    private const val CONNECT_TIMEOUT_MS = 5000
    private const val READ_TIMEOUT_MS = 10000

    private val executor = Executors.newFixedThreadPool(4)
    private val activeLocks = java.util.concurrent.ConcurrentHashMap<String, Any>()

    @JvmStatic
    fun downloadHeadFile(fileIdHex: String, targetFilePath: String): Boolean {
        try {
            val targetFile = java.io.File(targetFilePath)
            if (targetFile.exists() && targetFile.length() >= MIN_HEAD_FILE_SIZE) {
                android.util.Log.i(TAG, "Head file cache hit: $targetFilePath (size=${targetFile.length()})")
                return true
            }

            // Synchronize on per-fileId lock to prevent concurrent colliding downloads
            val lock = activeLocks.computeIfAbsent(fileIdHex) { Any() }

            // Execute network operations strictly on background worker thread to prevent NetworkOnMainThreadException
            val future = executor.submit(Callable<Boolean> {
                synchronized(lock) {
                    downloadInternal(fileIdHex, targetFilePath)
                }
            })

            return future.get(15, TimeUnit.SECONDS)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Head file download execution failed for $fileIdHex", e)
            return false
        }
    }

    private fun downloadInternal(fileIdHex: String, targetFilePath: String): Boolean {
        val targetFile = java.io.File(targetFilePath)
        if (targetFile.exists() && targetFile.length() >= MIN_HEAD_FILE_SIZE) {
            return true
        }
        targetFile.parentFile?.mkdirs()

        val tempFile = java.io.File("${targetFilePath}_${System.nanoTime()}.tmp")

        try {
            val url = java.net.URL("$HEAD_CDN_BASE$fileIdHex")
            android.util.Log.i(TAG, "Downloading head file from $url to $targetFilePath")
            val connection = url.openConnection() as java.net.HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = CONNECT_TIMEOUT_MS
            connection.readTimeout = READ_TIMEOUT_MS
            connection.setRequestProperty("User-Agent", "Spotify/8.9.18 Android/34")
            connection.setRequestProperty("Accept-Encoding", "identity")

            val responseCode = connection.responseCode
            if (responseCode !in 200..299) {
                android.util.Log.e(TAG, "CDN returned HTTP code: $responseCode for $fileIdHex")
                return false
            }

            val expectedLength = connection.contentLengthLong

            tempFile.outputStream().use { output ->
                connection.inputStream.use { input ->
                    input.copyTo(output)
                }
            }

            val downloadedLength = tempFile.length()
            val isValid = if (expectedLength > 0L) {
                downloadedLength == expectedLength
            } else {
                downloadedLength >= MIN_HEAD_FILE_SIZE
            }

            if (!isValid) {
                android.util.Log.e(TAG, "Downloaded file length mismatch: $downloadedLength (expected $expectedLength)")
                tempFile.delete()
                return false
            }

            if (targetFile.exists()) {
                targetFile.delete()
            }
            val renamed = try {
                java.nio.file.Files.move(
                    tempFile.toPath(),
                    targetFile.toPath(),
                    java.nio.file.StandardCopyOption.REPLACE_EXISTING,
                    java.nio.file.StandardCopyOption.ATOMIC_MOVE
                )
                true
            } catch (_: Exception) {
                tempFile.renameTo(targetFile)
            }
            android.util.Log.i(TAG, "Head file download complete: $targetFilePath (size=$downloadedLength, expected=$expectedLength)")
            return renamed
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Exception downloading head file for $fileIdHex: ${e.message}", e)
            if (tempFile.exists()) {
                tempFile.delete()
            }
            return false
        }
    }
}

class MainActivity : FlutterActivity() {
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
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "sessionId is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

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

    private fun registerObserver() {
        if (observer == null) {
            observer = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    eventSink?.success("changed")
                }
            }
            contentResolver.registerContentObserver(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                true,
                observer!!
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
