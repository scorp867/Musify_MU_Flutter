package um.musify.mu.musify_mu

import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.GZIPInputStream

object NativeHttpBridge {
    private const val TAG = "MusifyHttp"

    @JvmStatic
    fun executeRequest(
        method: String,
        url: String,
        headerPairs: Array<String>,
        body: ByteArray?,
        connectTimeoutMs: Int,
        readTimeoutMs: Int,
    ): ByteArray? {
        var conn: HttpURLConnection? = null
        try {
            conn = (URL(url).openConnection() as HttpURLConnection).apply {
                requestMethod = method
                connectTimeout = if (connectTimeoutMs > 0) connectTimeoutMs else 10000
                readTimeout = if (readTimeoutMs > 0) readTimeoutMs else 15000
                instanceFollowRedirects = true
                useCaches = false
            }

            var i = 0
            while (i + 1 < headerPairs.size) {
                val key = headerPairs[i]
                val value = headerPairs[i + 1]
                if (key.isNotEmpty()) {
                    conn.setRequestProperty(key, value)
                }
                i += 2
            }

            if (body != null && body.isNotEmpty() && (method == "POST" || method == "PUT" || method == "PATCH")) {
                conn.doOutput = true
                conn.setFixedLengthStreamingMode(body.size)
                conn.outputStream.use { out ->
                    out.write(body)
                    out.flush()
                }
            }

            val statusCode = conn.responseCode
            val rawStream: InputStream? = try {
                if (statusCode in 200..399) conn.inputStream else conn.errorStream
            } catch (_: Exception) {
                conn.errorStream
            }

            val payloadBytes: ByteArray = if (rawStream != null) {
                val contentEncoding = conn.contentEncoding?.lowercase() ?: ""
                val decodedStream: InputStream = if (contentEncoding.contains("gzip")) {
                    GZIPInputStream(rawStream)
                } else {
                    rawStream
                }
                decodedStream.use { stream ->
                    val baos = ByteArrayOutputStream()
                    val buf = ByteArray(8192)
                    var n: Int
                    while (stream.read(buf).also { n = it } != -1) {
                        baos.write(buf, 0, n)
                    }
                    baos.toByteArray()
                }
            } else {
                ByteArray(0)
            }

            val out = ByteArray(4 + payloadBytes.size)
            out[0] = (statusCode and 0xFF).toByte()
            out[1] = ((statusCode ushr 8) and 0xFF).toByte()
            out[2] = ((statusCode ushr 16) and 0xFF).toByte()
            out[3] = ((statusCode ushr 24) and 0xFF).toByte()
            if (payloadBytes.isNotEmpty()) {
                System.arraycopy(payloadBytes, 0, out, 4, payloadBytes.size)
            }
            return out
        } catch (e: Exception) {
            Log.e(TAG, "HTTP $method $url failed: ${e.message}")
            return null
        } finally {
            try {
                conn?.disconnect()
            } catch (_: Exception) {
            }
        }
    }
}
