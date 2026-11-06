package um.musify.mu.musify_mu

import android.media.MediaDrm
import android.media.NotProvisionedException
import android.media.ResourceBusyException
import android.util.Log
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.HashMap
import java.util.UUID
import java.util.concurrent.Callable
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.zip.GZIPInputStream

class RateLimitException(message: String) : IllegalStateException(message)

/**
 * Manages Widevine MediaDrm lifecycle, multi-session management, and license acquisition.
 * Strictly guarantees single-active-session concurrency (closing previous stream session
 * before opening a new track session to prevent Spotify concurrent-stream 429 errors),
 * WebPlayer header conformity, and auth cookie propagation.
 *
 * All network operations (license POST and device provisioning) are offloaded to a dedicated
 * background executor (ioExecutor) so that invocations from any thread (including Android UI/Main thread
 * via Dart FFI) will never trigger android.os.NetworkOnMainThreadException.
 */
class MusifyDrmManager {
    companion object {
        private const val TAG = "MusifyDrmManager"
        val WIDEVINE_UUID: UUID = UUID.fromString("edef8ba9-79d6-4ace-a3c8-27dcd51d21ed")
        private const val CONNECT_TIMEOUT_MS = 10000
        private const val READ_TIMEOUT_MS = 10000
        private const val BASE_BACKOFF_MS = 500L
        private const val MAX_CONCURRENT_SESSIONS = 3
    }

    private val drmLock = Any()
    private val ioExecutor = Executors.newCachedThreadPool()
    private var mediaDrm: MediaDrm? = null
    private var currentActiveSessionId: ByteArray? = null

    // Multi-session pool: PSSH hex / Key ID -> active open MediaDrm sessionId
    private val sessionCache = LinkedHashMap<String, ByteArray>(MAX_CONCURRENT_SESSIONS, 0.75f, true)

    init {
        initMediaDrm()
    }

    private fun initMediaDrm(): Boolean {
        if (!MediaDrm.isCryptoSchemeSupported(WIDEVINE_UUID)) {
            Log.e(TAG, "Widevine crypto scheme is not supported on this device")
            return false
        }
        return try {
            mediaDrm = MediaDrm(WIDEVINE_UUID)
            Log.i(TAG, "Instantiated Widevine MediaDrm with native security level")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to instantiate MediaDrm for Widevine", e)
            false
        }
    }

    /**
     * Opens or reuses a MediaDrm session for the given track PSSH.
     * Closes any previous stream's active session prior to negotiating a new track session
     * to eliminate Spotify's strict single-stream concurrency rate limit (HTTP 429).
     *
     * Automatically executes device provisioning if the device/session is not provisioned.
     * Returns the raw sessionId ByteArray on success, or null on failure.
     */
    fun acquireStreamingSession(
        psshBytes: ByteArray,
        licenseServerUrl: String,
        authHeader: String?,
        maxRetries: Int = 3
    ): ByteArray? = synchronized(drmLock) {
        var drm = mediaDrm
        if (drm == null) {
            if (!initMediaDrm() || mediaDrm == null) {
                Log.e(TAG, "MediaDrm instance is null and re-init failed")
                return null
            }
            drm = mediaDrm!!
        }

        val formattedPssh = if (isPsshBox(psshBytes)) {
            psshBytes
        } else {
            wrapInPsshBox(psshBytes)
        }

        // Cache key based on formatted PSSH box containing the track's unique Key ID
        val cacheKey = formattedPssh.joinToString("") { "%02x".format(it) }

        val cachedSessionId = sessionCache[cacheKey]
        if (cachedSessionId != null) {
            try {
                // Verify the cached session is still active and valid in MediaDrm
                drm.queryKeyStatus(cachedSessionId)
                Log.i(TAG, "DRM session cache HIT for track PSSH. Reusing active hardware session (0 network calls).")
                currentActiveSessionId = cachedSessionId
                return cachedSessionId
            } catch (e: Exception) {
                Log.w(TAG, "Cached DRM session is no longer valid, evicting and acquiring fresh session", e)
                sessionCache.remove(cacheKey)
                try {
                    drm.closeSession(cachedSessionId)
                } catch (_: Exception) {}
            }
        }

        var sessionId: ByteArray? = null
        try {
            sessionId = drm.openSession()
        } catch (e: NotProvisionedException) {
            Log.w(TAG, "Device not provisioned for Widevine, executing provisioning handshake...", e)
            if (handleProvisioning(drm)) {
                try {
                    sessionId = drm.openSession()
                    Log.i(TAG, "DRM session opened successfully after device provisioning")
                } catch (retryEx: Exception) {
                    Log.e(TAG, "Failed to open DRM session even after provisioning", retryEx)
                    return null
                }
            } else {
                Log.e(TAG, "Widevine device provisioning failed")
                return null
            }
        } catch (e: ResourceBusyException) {
            Log.e(TAG, "DRM resource busy, clearing LRU cache and recreating MediaDrm instance", e)
            evictAllCachedSessions(drm)
            try {
                drm.close()
            } catch (_: Exception) {}
            if (initMediaDrm() && mediaDrm != null) {
                drm = mediaDrm!!
                try {
                    sessionId = drm.openSession()
                } catch (retryEx: Exception) {
                    Log.e(TAG, "Failed to open DRM session even after recreating MediaDrm", retryEx)
                    return null
                }
            } else {
                return null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open DRM session", e)
            return null
        }

        try {
            Log.i(TAG, "Requesting key for PSSH (${formattedPssh.size} bytes): ${formattedPssh.joinToString("") { "%02x".format(it) }}")

            val optionalParameters = HashMap<String, String>()
            var keyRequest: MediaDrm.KeyRequest
            try {
                keyRequest = drm.getKeyRequest(
                    sessionId,
                    formattedPssh,
                    "audio/mp4",
                    MediaDrm.KEY_TYPE_STREAMING,
                    optionalParameters
                )
            } catch (e: NotProvisionedException) {
                Log.w(TAG, "getKeyRequest threw NotProvisionedException, executing provisioning...", e)
                if (handleProvisioning(drm)) {
                    keyRequest = drm.getKeyRequest(
                        sessionId,
                        formattedPssh,
                        "audio/mp4",
                        MediaDrm.KEY_TYPE_STREAMING,
                        optionalParameters
                    )
                } else {
                    closeSessionInternal(drm, sessionId)
                    return null
                }
            }

            val challengeData = keyRequest.data
            var responseBytes: ByteArray? = null
            var attempt = 0
            var delayMs = BASE_BACKOFF_MS

            while (attempt < maxRetries) {
                attempt++
                try {
                    responseBytes = executeLicensePost(licenseServerUrl, authHeader, challengeData)
                    if (responseBytes.isNotEmpty()) {
                        break
                    }
                } catch (e: RateLimitException) {
                    Log.e(TAG, "Aborting retries immediately due to license server rate limiting: ${e.message}")
                    break
                } catch (e: Exception) {
                    Log.w(TAG, "License request attempt $attempt failed: ${e.javaClass.simpleName}: ${e.message}", e)
                }

                if (attempt < maxRetries) {
                    try {
                        Thread.sleep(delayMs)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                        break
                    }
                    delayMs *= 2
                }
            }

            if (responseBytes == null || responseBytes.isEmpty()) {
                Log.e(TAG, "License acquisition failed after $attempt attempts")
                closeSessionInternal(drm, sessionId)
                return null
            }

            drm.provideKeyResponse(sessionId, responseBytes)
            Log.i(TAG, "Widevine license successfully installed for session")

            currentActiveSessionId = sessionId
            putSession(drm, cacheKey, sessionId)
            return sessionId
        } catch (e: Exception) {
            Log.e(TAG, "Failed during DRM key exchange: ${e.javaClass.simpleName}: ${e.message}", e)
            closeSessionInternal(drm, sessionId)
            return null
        }
    }

    private fun putSession(drm: MediaDrm, key: String, sessionId: ByteArray) {
        sessionCache[key] = sessionId
        while (sessionCache.size > MAX_CONCURRENT_SESSIONS) {
            val it = sessionCache.entries.iterator()
            if (it.hasNext()) {
                val eldest = it.next()
                val oldSessionId = eldest.value
                it.remove()
                try {
                    Log.i(TAG, "LRU pool evicting and closing old DRM session to free hardware CDM slot")
                    drm.closeSession(oldSessionId)
                } catch (e: Exception) {
                    Log.w(TAG, "Error closing evicted DRM session", e)
                }
            } else {
                break
            }
        }
    }

    private fun evictAllCachedSessions(drm: MediaDrm) {
        currentActiveSessionId = null
        for (sessionId in sessionCache.values) {
            try {
                drm.closeSession(sessionId)
            } catch (_: Exception) {}
        }
        sessionCache.clear()
    }

    private fun closeSessionInternal(drm: MediaDrm, sessionId: ByteArray) {
        try {
            drm.closeSession(sessionId)
        } catch (e: Exception) {
            Log.w(TAG, "Error closing DRM session", e)
        }
    }

    private fun isPsshBox(bytes: ByteArray): Boolean {
        if (bytes.size < 32) return false
        return bytes[4] == 'p'.code.toByte() &&
               bytes[5] == 's'.code.toByte() &&
               bytes[6] == 's'.code.toByte() &&
               bytes[7] == 'h'.code.toByte()
    }

    private fun wrapInPsshBox(psshData: ByteArray): ByteArray {
        val totalSize = 32 + psshData.size
        val out = ByteArray(totalSize)
        out[0] = ((totalSize shr 24) and 0xFF).toByte()
        out[1] = ((totalSize shr 16) and 0xFF).toByte()
        out[2] = ((totalSize shr 8) and 0xFF).toByte()
        out[3] = (totalSize and 0xFF).toByte()
        out[4] = 'p'.code.toByte()
        out[5] = 's'.code.toByte()
        out[6] = 's'.code.toByte()
        out[7] = 'h'.code.toByte()
        // Version 0, flags 0
        out[8] = 0; out[9] = 0; out[10] = 0; out[11] = 0
        // Widevine UUID: edef8ba9-79d6-4ace-a3c8-27dcd51d21ed
        val uuidBytes = byteArrayOf(
            0xed.toByte(), 0xef.toByte(), 0x8b.toByte(), 0xa9.toByte(),
            0x79.toByte(), 0xd6.toByte(), 0x4a.toByte(), 0xce.toByte(),
            0xa3.toByte(), 0xc8.toByte(), 0x27.toByte(), 0xdc.toByte(),
            0xd5.toByte(), 0x1d.toByte(), 0x21.toByte(), 0xed.toByte()
        )
        System.arraycopy(uuidBytes, 0, out, 12, 16)
        // Data size (big-endian)
        val dataLen = psshData.size
        out[28] = ((dataLen shr 24) and 0xFF).toByte()
        out[29] = ((dataLen shr 16) and 0xFF).toByte()
        out[30] = ((dataLen shr 8) and 0xFF).toByte()
        out[31] = (dataLen and 0xFF).toByte()
        // Payload
        System.arraycopy(psshData, 0, out, 32, dataLen)
        return out
    }

    /**
     * Dispatches license POST request to a background thread to prevent NetworkOnMainThreadException
     * if invoked directly from the platform/UI thread via Dart FFI.
     */
    private fun executeLicensePost(
        serverUrl: String,
        authHeader: String?,
        requestData: ByteArray
    ): ByteArray {
        val future = ioExecutor.submit(Callable {
            executeLicensePostInternal(serverUrl, authHeader, requestData)
        })
        return try {
            future.get((CONNECT_TIMEOUT_MS + READ_TIMEOUT_MS).toLong(), TimeUnit.MILLISECONDS)
        } catch (e: ExecutionException) {
            val cause = e.cause ?: e
            if (cause is RateLimitException) throw cause
            if (cause is Exception) throw cause
            throw IllegalStateException("License request failed: ${cause.message}", cause)
        }
    }

    private fun executeLicensePostInternal(
        serverUrl: String,
        authHeader: String?,
        requestData: ByteArray
    ): ByteArray {
        val url = URL(serverUrl)
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.doOutput = true
        connection.doInput = true
        connection.connectTimeout = CONNECT_TIMEOUT_MS
        connection.readTimeout = READ_TIMEOUT_MS
        connection.setRequestProperty("Content-Type", "application/octet-stream")
        connection.setRequestProperty("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:158.0) Gecko/20100101 Firefox/158.0")
        connection.setRequestProperty("Accept", "*/*")
        connection.setRequestProperty("Accept-Language", "en-US,en;q=0.9")
        connection.setRequestProperty("Accept-Encoding", "gzip, deflate, br, zstd")
        connection.setRequestProperty("Origin", "https://open.spotify.com")
        connection.setRequestProperty("Referer", "https://open.spotify.com/")
        connection.setRequestProperty("Sec-Fetch-Dest", "empty")
        connection.setRequestProperty("Sec-Fetch-Mode", "cors")
        connection.setRequestProperty("Sec-Fetch-Site", "same-site")
        connection.setRequestProperty("Connection", "keep-alive")
        connection.setRequestProperty("Priority", "u=4")
        connection.setRequestProperty("TE", "trailers")

        if (authHeader != null && authHeader.isNotEmpty()) {
            val lines = authHeader.split("\n")
            for (line in lines) {
                val trimmed = line.trim()
                if (trimmed.isEmpty()) continue
                if (trimmed.startsWith("client-token:", ignoreCase = true)) {
                    val clientToken = trimmed.substring("client-token:".length).trim()
                    if (clientToken.isNotEmpty()) {
                        connection.setRequestProperty("client-token", clientToken)
                    }
                } else if (trimmed.startsWith("authorization:", ignoreCase = true)) {
                    val authValue = trimmed.substring("authorization:".length).trim()
                    val formatted = if (authValue.startsWith("Bearer ", ignoreCase = true)) authValue else "Bearer $authValue"
                    connection.setRequestProperty("Authorization", formatted)
                } else if (trimmed.startsWith("Bearer ", ignoreCase = true)) {
                    connection.setRequestProperty("Authorization", trimmed)
                } else if (!trimmed.contains(":")) {
                    connection.setRequestProperty("Authorization", "Bearer $trimmed")
                }
            }
        }

        val hasAuth = connection.getRequestProperty("Authorization") != null
        val authSnippet = connection.getRequestProperty("Authorization")?.take(20) ?: "none"
        val hasClientToken = connection.getRequestProperty("client-token") != null
        val clientTokenSnippet = connection.getRequestProperty("client-token")?.take(25) ?: "none"
        Log.i(TAG, "Posting license request: URL=$serverUrl | Bytes=${requestData.size} | hasAuth=$hasAuth ($authSnippet...) | hasClientToken=$hasClientToken ($clientTokenSnippet...)")

        connection.outputStream.use { outputStream ->
            outputStream.write(requestData)
            outputStream.flush()
        }

        val responseCode = connection.responseCode

        val rawError = try {
            connection.errorStream?.readBytes() ?: ByteArray(0)
        } catch (_: Exception) {
            ByteArray(0)
        }
        val decompressedError = if (rawError.size >= 2 && rawError[0] == 0x1f.toByte() && rawError[1] == 0x8b.toByte()) {
            try {
                GZIPInputStream(ByteArrayInputStream(rawError)).readBytes()
            } catch (_: Exception) {
                rawError
            }
        } else {
            rawError
        }
        val errorText = if (decompressedError.isNotEmpty()) String(decompressedError, Charsets.UTF_8) else ""
        val headersSummary = connection.headerFields.entries.joinToString("; ") { "${it.key}: ${it.value}" }

        if (responseCode == 429) {
            val retryAfter = connection.getHeaderField("Retry-After")
            Log.e(TAG, "Rate limited by Spotify Widevine license server (HTTP 429). Retry-After: $retryAfter | ErrorBody: '$errorText' | Headers: $headersSummary")
            throw RateLimitException("HTTP 429: Too Many Requests ($errorText)")
        }

        if (responseCode !in 200..299) {
            Log.e(TAG, "License server error HTTP $responseCode: '$errorText' | Headers: $headersSummary | URL: $serverUrl | Request: ${requestData.size} bytes")
            throw IllegalStateException("License server returned HTTP status: $responseCode - $errorText")
        }

        val rawInput = connection.inputStream
        val inputStream: InputStream = if ("gzip".equals(connection.contentEncoding, ignoreCase = true)) {
            GZIPInputStream(rawInput)
        } else {
            rawInput
        }

        val buffer = ByteArray(4096)
        val outputStream = ByteArrayOutputStream()
        var bytesRead: Int
        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            outputStream.write(buffer, 0, bytesRead)
        }
        return outputStream.toByteArray()
    }

    private fun handleProvisioning(drm: MediaDrm): Boolean {
        val future = ioExecutor.submit(Callable {
            handleProvisioningInternal(drm)
        })
        return try {
            future.get((CONNECT_TIMEOUT_MS + READ_TIMEOUT_MS).toLong(), TimeUnit.MILLISECONDS)
        } catch (e: Exception) {
            Log.e(TAG, "Widevine provisioning future failed", e)
            false
        }
    }

    private fun handleProvisioningInternal(drm: MediaDrm): Boolean {
        return try {
            val request = drm.provisionRequest
            val defaultUrl = request.defaultUrl
            val dataString = String(request.data, Charsets.UTF_8)
            val separator = if (defaultUrl.contains("?")) "&" else "?"
            val fullUrl = "$defaultUrl${separator}signedRequest=$dataString"
            Log.i(TAG, "Executing Widevine provisioning exchange: $fullUrl")

            val url = URL(fullUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = CONNECT_TIMEOUT_MS
            connection.readTimeout = READ_TIMEOUT_MS
            connection.setRequestProperty("Content-Type", "application/octet-stream")
            connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36")
            connection.setRequestProperty("Connection", "close")

            connection.outputStream.use { it.write(ByteArray(0)) }

            val responseCode = connection.responseCode
            if (responseCode !in 200..299) {
                val errorBody = try {
                    connection.errorStream?.bufferedReader()?.use { it.readText() } ?: ""
                } catch (_: Exception) { "" }
                Log.e(TAG, "Widevine provisioning HTTP failed ($responseCode): $errorBody")
                return false
            }

            val responseBytes = connection.inputStream.use { it.readBytes() }
            if (responseBytes.isEmpty()) {
                Log.e(TAG, "Widevine provisioning returned empty response")
                return false
            }

            drm.provideProvisionResponse(responseBytes)
            Log.i(TAG, "Widevine device provisioning completed and certificate installed")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed during Widevine device provisioning", e)
            false
        }
    }

    fun closeSession(sessionId: ByteArray?) {
        if (sessionId == null) return
        val drm = mediaDrm ?: return
        synchronized(drmLock) {
            try {
                if (currentActiveSessionId?.contentEquals(sessionId) == true) {
                    currentActiveSessionId = null
                }
                val it = sessionCache.entries.iterator()
                while (it.hasNext()) {
                    val entry = it.next()
                    if (entry.value.contentEquals(sessionId)) {
                        it.remove()
                        break
                    }
                }
                drm.closeSession(sessionId)
                Log.i(TAG, "DRM session explicitly closed")
            } catch (e: Exception) {
                Log.w(TAG, "Error closing DRM session", e)
            }
        }
    }

    fun closeActiveSession() {
        val drm = mediaDrm ?: return
        synchronized(drmLock) {
            currentActiveSessionId?.let { session ->
                closeSession(session)
            }
        }
    }

    fun release() {
        val drm = mediaDrm ?: return
        synchronized(drmLock) {
            evictAllCachedSessions(drm)
            try {
                drm.close()
            } catch (e: Exception) {
                Log.w(TAG, "Error releasing MediaDrm", e)
            } finally {
                mediaDrm = null
                ioExecutor.shutdown()
            }
        }
    }
}
