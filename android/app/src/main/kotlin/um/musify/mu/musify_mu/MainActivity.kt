package um.musify.mu.musify_mu

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "musify_mu/mediastore_observer"
    private var eventSink: EventChannel.EventSink? = null
    private var observer: ContentObserver? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
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
