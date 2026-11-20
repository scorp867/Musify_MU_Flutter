package um.musify.mu.musify_mu.connect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.media.VolumeProviderCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

/**
 * Android System Volume Observation & Remote Hardware Volume Key Bridge for Spotify Connect.
 *
 * Replicates Spotify Android's bidirectional local and remote volume pipeline:
 * - Local `STREAM_MUSIC` volume observation via `ContentObserver` on `Settings.System.CONTENT_URI`
 *   (`notifyForDescendants = true`), reading `AudioManager.getStreamVolume(STREAM_MUSIC=3)` /
 *   `getStreamMaxVolume(3)` normalized to Connect 16-bit (`0..65535`) scale:
 *   `p199p/vbr.java:739-742`, `p199p/a8h1.java:719-724`, `p199p/cl9.java:41-48`,
 *   `p199p/esq.java:14-24`, `p199p/ih7.java:68`, `p199p/gel1.java:1239-1241`, `p199p/stq.java:41-44`.
 * - Remote hardware volume key and system slider interception via `MediaSessionCompat` and
 *   `VolumeProviderCompat` (`MediaSessionCompat.setPlaybackToRemote(...)` with `isActive = true`
 *   and non-stopped `PlaybackStateCompat` when a remote Connect device is active; restoring
 *   `MediaSessionCompat.setPlaybackToLocal(STREAM_MUSIC)` and `isActive = false` when local):
 *   `p199p/fth1.java`, `p199p/pce1.java:458-503`, `p199p/qdk.java:380-436,619-633,719-744`,
 *   `p199p/buh1.java`, `p199p/hr81.java`, `p199p/lw51.java:315,330`, `p199p/a0f1.java:421`.
 */
class SystemVolumeBridge(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    companion object {
        private const val TAG = "[CONNECT-KOTLIN]"
        const val CONTROL_CHANNEL_NAME = "um.musify.mu/connect/system_volume_control"
        const val EVENTS_CHANNEL_NAME = "um.musify.mu/connect/system_volume_events"

        private const val MEDIA_SESSION_TAG = "MusifyConnectRemoteVolume"
        private const val ACTION_VOLUME_CHANGED = "android.media.VOLUME_CHANGED_ACTION"
        private const val EXTRA_VOLUME_STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE"
        private const val MAX_CONNECT_VOLUME = 65535
        private const val DEFAULT_VOLUME_STEPS = 32
        private const val SELF_ECHO_SUPPRESSION_WINDOW_MS = 450L
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager

    private var controlChannel: MethodChannel? = null
    private var eventsChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var settingsObserverRegistered = false
    private var volumeReceiverRegistered = false

    private var lastObservedStep: Int = -1
    private var lastSelfSetStep: Int = -1
    private var suppressObserverUntilElapsedMs: Long = 0L

    private var mediaSession: MediaSessionCompat? = null
    private var activeVolumeProvider: VolumeProviderCompat? = null
    private var remoteHardwareVolumeEnabled: Boolean = false
    private var currentRemoteMaxSteps: Int = DEFAULT_VOLUME_STEPS

    private val settingsContentObserver = object : ContentObserver(mainHandler) {
        override fun onChange(selfChange: Boolean, uri: Uri?) {
            super.onChange(selfChange, uri)
            handleLocalStreamVolumeCheck()
        }
    }

    private val volumeChangedReceiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context?, intent: Intent?) {
            if (intent?.action != ACTION_VOLUME_CHANGED) return
            val streamType = intent.getIntExtra(EXTRA_VOLUME_STREAM_TYPE, AudioManager.STREAM_MUSIC)
            if (streamType == AudioManager.STREAM_MUSIC) {
                mainHandler.post {
                    handleLocalStreamVolumeCheck()
                }
            }
        }
    }

    fun register(messenger: BinaryMessenger) {
        controlChannel = MethodChannel(messenger, CONTROL_CHANNEL_NAME).apply {
            setMethodCallHandler(this@SystemVolumeBridge)
        }
        eventsChannel = EventChannel(messenger, EVENTS_CHANNEL_NAME).apply {
            setStreamHandler(this@SystemVolumeBridge)
        }
        registerLocalVolumeObservers()
        Log.i(TAG, "SystemVolumeBridge registered on $CONTROL_CHANNEL_NAME and $EVENTS_CHANNEL_NAME")
    }

    fun detach() {
        unregisterLocalVolumeObservers()
        releaseRemoteMediaSession()
        eventSink = null
        controlChannel?.setMethodCallHandler(null)
        controlChannel = null
        eventsChannel?.setStreamHandler(null)
        eventsChannel = null
        Log.i(TAG, "SystemVolumeBridge detached")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getLocalVolume" -> {
                try {
                    result.success(readLocalVolumeMap())
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to read local STREAM_MUSIC volume: ${e.message}", e)
                    result.error(
                        "LOCAL_VOLUME_READ_ERROR",
                        "Failed to read local volume: ${e.message}",
                        null
                    )
                }
            }
            "setLocalVolume" -> {
                val rawVolume = extractIntArgument(call, "volume")
                if (rawVolume == null) {
                    result.error("INVALID_ARGUMENT", "Missing required 'volume' integer argument", null)
                    return
                }
                val showUi = call.argument<Boolean>("showUi") ?: false
                try {
                    val applied = applyLocalVolume(rawVolume, showUi)
                    result.success(applied)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to set local STREAM_MUSIC volume: ${e.message}", e)
                    result.error(
                        "LOCAL_VOLUME_SET_ERROR",
                        "Failed to set local volume: ${e.message}",
                        null
                    )
                }
            }
            "configureRemoteHardwareVolume" -> {
                val enabled = call.argument<Boolean>("enabled")
                if (enabled == null) {
                    result.error("INVALID_ARGUMENT", "Missing required 'enabled' boolean argument", null)
                    return
                }
                val supportsVolume = call.argument<Boolean>("supportsVolume") ?: true
                val volumeSteps = extractIntArgument(call, "volumeSteps") ?: DEFAULT_VOLUME_STEPS
                val currentVolume = extractIntArgument(call, "currentVolume") ?: 0
                try {
                    val configured = configureRemoteVolumeInterception(
                        enabled = enabled,
                        supportsVolume = supportsVolume,
                        volumeSteps = volumeSteps,
                        currentVolume = currentVolume
                    )
                    result.success(configured)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to configure remote hardware volume interception: ${e.message}", e)
                    result.error(
                        "REMOTE_VOLUME_CONFIG_ERROR",
                        "Failed to configure remote hardware volume: ${e.message}",
                        null
                    )
                }
            }
            "updateRemoteHardwareVolume" -> {
                val currentVolume = extractIntArgument(call, "currentVolume")
                    ?: extractIntArgument(call, "volume")
                if (currentVolume == null) {
                    result.error(
                        "INVALID_ARGUMENT",
                        "Missing required 'currentVolume' integer argument",
                        null
                    )
                    return
                }
                try {
                    val updated = updateRemoteVolumeStep(currentVolume)
                    result.success(updated)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to update remote hardware volume step: ${e.message}", e)
                    result.error(
                        "REMOTE_VOLUME_UPDATE_ERROR",
                        "Failed to update remote hardware volume: ${e.message}",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        registerLocalVolumeObservers()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun extractIntArgument(call: MethodCall, key: String): Int? {
        val number = call.argument<Number>(key)
        if (number != null) return number.toInt()
        val raw = call.arguments
        if (raw is Number) return raw.toInt()
        return null
    }

    private fun registerLocalVolumeObservers() {
        val manager = audioManager
        if (manager != null) {
            try {
                val maxSteps = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                lastObservedStep = manager.getStreamVolume(AudioManager.STREAM_MUSIC).coerceIn(0, maxSteps)
            } catch (e: Exception) {
                Log.w(TAG, "Unable to initialize lastObservedStep: ${e.message}")
            }
        }

        if (!settingsObserverRegistered) {
            try {
                context.contentResolver.registerContentObserver(
                    Settings.System.CONTENT_URI,
                    true,
                    settingsContentObserver
                )
                settingsObserverRegistered = true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to register Settings.System ContentObserver: ${e.message}")
            }
        }

        if (!volumeReceiverRegistered) {
            try {
                val filter = IntentFilter(ACTION_VOLUME_CHANGED)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.registerReceiver(
                        volumeChangedReceiver,
                        filter,
                        Context.RECEIVER_NOT_EXPORTED
                    )
                } else {
                    ContextCompat.registerReceiver(
                        context,
                        volumeChangedReceiver,
                        filter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                }
                volumeReceiverRegistered = true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to register VOLUME_CHANGED_ACTION receiver: ${e.message}")
            }
        }
    }

    private fun unregisterLocalVolumeObservers() {
        if (settingsObserverRegistered) {
            try {
                context.contentResolver.unregisterContentObserver(settingsContentObserver)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to unregister Settings.System ContentObserver: ${e.message}")
            }
            settingsObserverRegistered = false
        }
        if (volumeReceiverRegistered) {
            try {
                context.unregisterReceiver(volumeChangedReceiver)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to unregister VOLUME_CHANGED_ACTION receiver: ${e.message}")
            }
            volumeReceiverRegistered = false
        }
    }

    private fun readLocalVolumeMap(): Map<String, Any> {
        val manager = audioManager
            ?: throw IllegalStateException("AudioManager system service is unavailable")
        val maxSteps = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        val currentStep = manager.getStreamVolume(AudioManager.STREAM_MUSIC).coerceIn(0, maxSteps)
        val scaledVolume = ((currentStep.toDouble() / maxSteps.toDouble()) * MAX_CONNECT_VOLUME.toDouble())
            .roundToInt()
            .coerceIn(0, MAX_CONNECT_VOLUME)

        lastObservedStep = currentStep
        return mapOf(
            "volume" to scaledVolume,
            "steps" to maxSteps,
            "currentStep" to currentStep
        )
    }

    private fun applyLocalVolume(rawConnectVolume: Int, showUi: Boolean): Boolean {
        val manager = audioManager ?: return false
        val maxSteps = manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        val clampedVolume = rawConnectVolume.coerceIn(0, MAX_CONNECT_VOLUME)
        val targetStep = ((clampedVolume.toDouble() / MAX_CONNECT_VOLUME.toDouble()) * maxSteps.toDouble())
            .roundToInt()
            .coerceIn(0, maxSteps)

        lastSelfSetStep = targetStep
        lastObservedStep = targetStep
        suppressObserverUntilElapsedMs =
            SystemClock.elapsedRealtime() + SELF_ECHO_SUPPRESSION_WINDOW_MS

        val flags = if (showUi) AudioManager.FLAG_SHOW_UI else 0
        manager.setStreamVolume(AudioManager.STREAM_MUSIC, targetStep, flags)
        return true
    }

    private fun handleLocalStreamVolumeCheck() {
        val manager = audioManager ?: return
        val maxSteps = try {
            manager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read getStreamMaxVolume in observer: ${e.message}")
            return
        }
        val currentStep = try {
            manager.getStreamVolume(AudioManager.STREAM_MUSIC).coerceIn(0, maxSteps)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read getStreamVolume in observer: ${e.message}")
            return
        }

        if (currentStep == lastObservedStep) {
            return
        }
        lastObservedStep = currentStep

        val nowElapsed = SystemClock.elapsedRealtime()
        if (nowElapsed <= suppressObserverUntilElapsedMs && currentStep == lastSelfSetStep) {
            return
        }

        val scaledVolume = ((currentStep.toDouble() / maxSteps.toDouble()) * MAX_CONNECT_VOLUME.toDouble())
            .roundToInt()
            .coerceIn(0, MAX_CONNECT_VOLUME)

        eventSink?.success(
            mapOf(
                "type" to "local_volume_changed",
                "volume" to scaledVolume,
                "steps" to maxSteps,
                "currentStep" to currentStep
            )
        )
    }

    /**
     * Configures or disables remote hardware volume button & slider interception via
     * `MediaSessionCompat` and `VolumeProviderCompat`, matching `p199p/qdk.java:380-436`
     * and `p199p/fth1.java`.
     *
     * Mandatory Android runtime rules:
     * - When `enabled = true`: sets `mediaSession.isActive = true` AND a non-stopped
     *   `PlaybackStateCompat` (`STATE_PLAYING`) so Android routes hardware volume keys to
     *   `VolumeProviderCompat` instead of local `STREAM_MUSIC`.
     * - Uses `VOLUME_CONTROL_ABSOLUTE` when `supportsVolume && volumeSteps > 0`, otherwise
     *   `VOLUME_CONTROL_FIXED`.
     * - Ignores `AudioManager.ADJUST_SAME (0)` in `onAdjustVolume` and emits only `-1` or `+1`.
     * - When `enabled = false`: calls `setPlaybackToLocal(STREAM_MUSIC)` and `isActive = false`.
     */
    private fun configureRemoteVolumeInterception(
        enabled: Boolean,
        supportsVolume: Boolean,
        volumeSteps: Int,
        currentVolume: Int
    ): Boolean {
        if (!enabled) {
            remoteHardwareVolumeEnabled = false
            activeVolumeProvider = null
            mediaSession?.let { session ->
                try {
                    session.setPlaybackToLocal(AudioManager.STREAM_MUSIC)
                    session.isActive = false
                } catch (e: Exception) {
                    Log.w(TAG, "Error reverting MediaSessionCompat to local playback: ${e.message}")
                }
            }
            return true
        }

        val session = ensureMediaSession()
        val maxSteps = maxOf(1, volumeSteps)
        currentRemoteMaxSteps = maxSteps
        val clampedVolume = currentVolume.coerceIn(0, MAX_CONNECT_VOLUME)
        val initialStep = ((maxSteps.toDouble() * clampedVolume.toDouble()) / MAX_CONNECT_VOLUME.toDouble())
            .roundToInt()
            .coerceIn(0, maxSteps)

        val controlType = if (supportsVolume && volumeSteps > 0) {
            VolumeProviderCompat.VOLUME_CONTROL_ABSOLUTE
        } else {
            VolumeProviderCompat.VOLUME_CONTROL_FIXED
        }

        val provider = object : VolumeProviderCompat(controlType, maxSteps, initialStep) {
            override fun onAdjustVolume(direction: Int) {
                // Ignore AudioManager.ADJUST_SAME (0) key-release / audio-focus callbacks
                if (direction == AudioManager.ADJUST_SAME) {
                    return
                }
                val normalizedDirection = if (direction > 0) 1 else -1
                if (controlType == VOLUME_CONTROL_ABSOLUTE) {
                    val nextStep = (this.currentVolume + normalizedDirection).coerceIn(0, maxSteps)
                    this.currentVolume = nextStep
                }
                mainHandler.post {
                    eventSink?.success(
                        mapOf(
                            "type" to "remote_volume_adjust",
                            "direction" to normalizedDirection
                        )
                    )
                }
            }

            override fun onSetVolumeTo(volume: Int) {
                if (controlType != VOLUME_CONTROL_ABSOLUTE) {
                    return
                }
                val safeStep = volume.coerceIn(0, maxSteps)
                this.currentVolume = safeStep
                val scaledConnectVolume =
                    ((safeStep.toDouble() * MAX_CONNECT_VOLUME.toDouble()) / maxSteps.toDouble())
                        .roundToInt()
                        .coerceIn(0, MAX_CONNECT_VOLUME)

                mainHandler.post {
                    eventSink?.success(
                        mapOf(
                            "type" to "remote_volume_set",
                            "volume" to scaledConnectVolume
                        )
                    )
                }
            }
        }

        val activePlaybackState = PlaybackStateCompat.Builder()
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS
            )
            .setState(
                PlaybackStateCompat.STATE_PLAYING,
                PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN,
                1.0f,
                SystemClock.elapsedRealtime()
            )
            .build()

        session.setPlaybackState(activePlaybackState)
        session.setPlaybackToRemote(provider)
        session.isActive = true

        activeVolumeProvider = provider
        remoteHardwareVolumeEnabled = true
        return true
    }

    private fun updateRemoteVolumeStep(currentVolume: Int): Boolean {
        val provider = activeVolumeProvider
        val maxSteps = maxOf(1, currentRemoteMaxSteps)
        val clampedVolume = currentVolume.coerceIn(0, MAX_CONNECT_VOLUME)
        val providerStep = ((maxSteps.toDouble() * clampedVolume.toDouble()) / MAX_CONNECT_VOLUME.toDouble())
            .roundToInt()
            .coerceIn(0, maxSteps)

        if (!remoteHardwareVolumeEnabled || provider == null) {
            return false
        }
        provider.currentVolume = providerStep
        return true
    }

    private fun ensureMediaSession(): MediaSessionCompat {
        mediaSession?.let { return it }
        val created = MediaSessionCompat(context, MEDIA_SESSION_TAG)
        mediaSession = created
        return created
    }

    private fun releaseRemoteMediaSession() {
        remoteHardwareVolumeEnabled = false
        activeVolumeProvider = null
        mediaSession?.let { session ->
            try {
                session.setPlaybackToLocal(AudioManager.STREAM_MUSIC)
                session.isActive = false
                session.release()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to release MediaSessionCompat cleanly: ${e.message}")
            }
        }
        mediaSession = null
    }
}
