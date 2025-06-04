package com.example.lut_transformer

import android.app.Activity
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference

/**
 * Main plugin class for LUT Transformer.
 * Handles communication between Flutter and native Android code.
 */
class LutTransformerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activityBinding: ActivityPluginBinding? = null
    private var flutterPluginBindingInstance: FlutterPlugin.FlutterPluginBinding? = null
    private var eventSink: EventChannel.EventSink? = null

    // Coroutine scope for managing background tasks
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    companion object {
        private const val METHOD_CHANNEL_NAME = "lut_transformer/method"
        private const val EVENT_CHANNEL_NAME = "lut_transformer/event"
        private const val TAG = "LutTransformerPlugin"
    }

    /**
     * Called when the plugin is attached to the Flutter engine.
     * Initializes MethodChannel and EventChannel.
     */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBindingInstance = flutterPluginBinding
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
        Log.d(TAG, "LutTransformerPlugin attached to engine.")
    }

    /**
     * Handles method calls from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "transformVideo" -> {
                val inputPath = call.argument<String>("inputPath")
                val lutAsset = call.argument<String?>("lutAsset")
                val flipHorizontally = call.argument<Boolean>("flipHorizontally") ?: false
                val cropSquareSize = call.argument<Int?>("cropSquareSize")

                if (inputPath == null) {
                    result.error("INVALID_ARGUMENTS", "InputPath is null.", null)
                    return
                }

                val activity = activityBinding?.activity
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity not available. Cannot start transformation.", null)
                    Log.w(TAG, "transformVideo called but no activity is available.")
                    return
                }
                val assets = flutterPluginBindingInstance?.flutterAssets
                if (assets == null) {
                    result.error("NO_FLUTTER_ASSETS", "Flutter assets not available.", null)
                    Log.w(TAG, "transformVideo called but Flutter assets are not available.")
                    return
                }
                startVideoTransformation(WeakReference(activity), assets, inputPath, lutAsset, flipHorizontally, cropSquareSize)
                result.success(null) // Acknowledge the call, actual result/progress via EventChannel
            }
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Starts the video transformation process in a coroutine.
     *
     * @param activityRef WeakReference to the current Activity.
     * @param assets FlutterAssets for accessing plugin assets.
     * @param inputPath Path to the input video file.
     * @param lutAsset Asset path for the LUT file.
     * @param flipHorizontally Whether to flip the video horizontally.
     */
    private fun startVideoTransformation(
        activityRef: WeakReference<Activity>,
        assets: FlutterPlugin.FlutterAssets,
        inputPath: String,
        lutAsset: String?,
        flipHorizontally: Boolean,
        cropSquareSize: Int?
    ) {
        scope.launch {
            val activity = activityRef.get()
            if (activity == null || activity.isFinishing || activity.isDestroyed) {
                 Log.w(TAG, "Activity is null or finishing/destroyed. Cannot start transformation.")
                 eventSink?.error("NO_ACTIVITY_AVAILABLE", "Activity was lost or destroyed before transformation could start.", null)
                 return@launch
            }

            try {
                VideoTransformer.transform(
                    activity,
                    assets,
                    inputPath,
                    lutAsset,
                    flipHorizontally,
                    cropSquareSize,
                    onProgress = { progress ->
                        // Ensure events are sent on the main thread
                        scope.launch(Dispatchers.Main) {
                           eventSink?.success(mapOf("progress" to progress))
                        }
                    },
                    onCompleted = { outputPath ->
                         scope.launch(Dispatchers.Main) {
                            eventSink?.success(mapOf("progress" to 1.0, "outputPath" to outputPath))
                            eventSink?.endOfStream() // Signal that the stream is complete
                         }
                    },
                    onError = { errorCode, errorMessage, errorDetails ->
                        scope.launch(Dispatchers.Main) {
                            eventSink?.error(errorCode, errorMessage, errorDetails)
                            eventSink?.endOfStream() // Signal that the stream is complete even on error
                        }
                    }
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error during video transformation setup: ${e.message}", e)
                scope.launch(Dispatchers.Main) {
                    eventSink?.error("TRANSFORM_SETUP_EXCEPTION", e.localizedMessage ?: "Unknown transformation setup error", e.stackTraceToString())
                    eventSink?.endOfStream() // Signal stream completion on setup exception
                }
            }
        }
    }

    /**
     * Called when Flutter starts listening to the EventChannel.
     */
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
        Log.d(TAG, "EventChannel onListen called.")
    }

    /**
     * Called when Flutter stops listening to the EventChannel.
     */
    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "EventChannel onCancel called.")
        this.eventSink = null
        // If VideoTransformer has a way to cancel ongoing operations, it should be called here.
        // For example: VideoTransformer.cancelCurrentTransformation()
    }

    /**
     * Called when the plugin is detached from the Flutter engine.
     * Cleans up resources.
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        this.flutterPluginBindingInstance = null
        scope.cancel() // Cancel all coroutines launched by this plugin
        Log.d(TAG, "LutTransformerPlugin detached from engine.")
    }

    // ActivityAware lifecycle methods
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activityBinding = binding
        Log.d(TAG, "Attached to activity.")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // This method is called when the activity is destroyed for a configuration change.
        // The activity will be reattached shortly. For this plugin, we don't clear
        // activityBinding here to potentially allow ongoing operations to complete
        // if they don't rely on a specific Activity instance that's being destroyed.
        // If there were long-running tasks holding strong references to the specific
        // activity context, more careful handling or nullifying activityBinding would be needed.
        Log.d(TAG, "Detached from activity for config changes.")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activityBinding = binding
        Log.d(TAG, "Reattached to activity for config changes.")
    }

    override fun onDetachedFromActivity() {
        // Activity is being destroyed. Clean up resources that are tied to the activity.
        Log.d(TAG, "Detached from activity.")
        this.activityBinding = null
    }
}
