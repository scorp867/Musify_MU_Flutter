package um.musify.mu.musify_mu

import android.media.MediaDrm
import android.media.NotProvisionedException
import android.media.ResourceBusyException
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.HashMap
import java.util.UUID

/**
 * Manages Widevine MediaDrm lifecycle, session negotiation, and license acquisition.
 * Executes HTTP license exchange with exponential backoff retries.
 */
class MusifyDrmManager {
    companion object {
        private const val TAG = "MusifyDrmManager"
        val WIDEVINE_UUID: UUID = UUID.fromString("edef8ba9-79d6-4ace-a3c8-27dcd51d21ed")
        private const val CONNECT_TIMEOUT_MS = 10000
        private const val READ_TIMEOUT_MS = 10000
        private const val BASE_BACKOFF_MS = 500L
    }

    private var mediaDrm: MediaDrm? = null

    init {
        if (MediaDrm.isCryptoSchemeSupported(WIDEVINE_UUID)) {
            try {
                mediaDrm = MediaDrm(WIDEVINE_UUID)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to instantiate MediaDrm for Widevine", e)
            }
        } else {
            Log.e(TAG, "Widevine crypto scheme is not supported on this device")
        }
    }

    /**
     * Opens a MediaDrm session, retrieves key challenge for the provided PSSH,
     * performs HTTP POST to the license server with exponential backoff,
     * and provides the key response back to the session.
     *
     * Returns the raw sessionId ByteArray on success, or null on failure.
     */
    fun acquireStreamingSession(
        psshBytes: ByteArray,
        licenseServerUrl: String,
        authHeader: String?,
        maxRetries: Int = 3
    ): ByteArray? {
        val drm = mediaDrm ?: run {
            Log.e(TAG, "MediaDrm instance is null")
            return null
        }

        var sessionId: ByteArray? = null
        try {
            sessionId = drm.openSession()
        } catch (e: NotProvisionedException) {
            Log.e(TAG, "Device not provisioned for Widevine", e)
            return null
        } catch (e: ResourceBusyException) {
            Log.e(TAG, "DRM resource busy", e)
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open DRM session", e)
            return null
        }

        try {
            val optionalParameters = HashMap<String, String>()
            val keyRequest = drm.getKeyRequest(
                sessionId,
                psshBytes,
                "audio/mp4",
                MediaDrm.KEY_TYPE_STREAMING,
                optionalParameters
            )

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
                } catch (e: Exception) {
                    Log.w(TAG, "License request attempt $attempt failed: ${e.message}")
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
                Log.e(TAG, "License acquisition failed after $maxRetries attempts")
                closeSession(sessionId)
                return null
            }

            drm.provideKeyResponse(sessionId, responseBytes)
            Log.i(TAG, "Widevine license successfully installed for session")
            return sessionId
        } catch (e: Exception) {
            Log.e(TAG, "Failed during DRM key exchange", e)
            closeSession(sessionId)
            return null
        }
    }

    private fun executeLicensePost(
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

        if (authHeader != null && authHeader.isNotEmpty()) {
            connection.setRequestProperty("Authorization", authHeader)
        }

        connection.outputStream.use { outputStream ->
            outputStream.write(requestData)
            outputStream.flush()
        }

        val responseCode = connection.responseCode
        if (responseCode !in 200..299) {
            throw IllegalStateException("License server returned HTTP status: $responseCode")
        }

        val inputStream: InputStream = connection.inputStream
        val buffer = ByteArray(4096)
        val outputStream = ByteArrayOutputStream()
        var bytesRead: Int
        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            outputStream.write(buffer, 0, bytesRead)
        }
        return outputStream.toByteArray()
    }

    fun closeSession(sessionId: ByteArray?) {
        if (sessionId == null) return
        try {
            mediaDrm?.closeSession(sessionId)
        } catch (e: Exception) {
            Log.w(TAG, "Error closing DRM session", e)
        }
    }

    fun release() {
        try {
            mediaDrm?.close()
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing MediaDrm", e)
        } finally {
            mediaDrm = null
        }
    }
}
