package com.example.lut_transformer

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.effect.Presentation
import androidx.media3.effect.SingleColorLut
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterAssets
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.File
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Handles the core video transformation logic using Media3 Transformer.
 */
object VideoTransformer {
    private const val TAG = "VideoTransformer"
    private var currentTransformer: Transformer? = null
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob()) // Use Default dispatcher for CPU-bound work
    private var progressJob: Job? = null

    // Constants for dummy progress simulation, as Transformer doesn't provide reliable progress updates yet.
    // TODO: Replace with actual progress reporting when Media3 Transformer API supports it better.
    private const val DUMMY_PROGRESS_DURATION_MS = 15000L // e.g., 15 seconds for dummy progress
    private const val DUMMY_PROGRESS_START_VALUE = 0.1 // Start dummy progress after initial setup
    private const val DUMMY_PROGRESS_END_VALUE = 0.9   // End dummy progress before actual completion
    private const val PROGRESS_UPDATE_INTERVAL_MS = 200L // Interval for dummy progress updates

    /**
     * Transforms a video by applying a LUT (.cube file) and a 1:1 aspect ratio crop.
     * Reports progress, completion, or errors via the provided callbacks.
     *
     * @param context The Android [Context].
     * @param flutterAssets For accessing plugin assets like the LUT file.
     * @param inputVideoPath The file path of the input video.
     * @param lutAssetKey The asset key for the .cube LUT file (e.g., "luts/my_lut.cube").
     * @param onProgress Callback for progress updates (0.0 to 1.0).
     * @param onCompleted Callback when transformation is successful, providing the output file path.
     * @param onError Callback for errors, providing an error code, message, and details.
     */
    fun transform(
        context: Context,
        flutterAssets: FlutterAssets,
        inputVideoPath: String,
        lutAssetKey: String,
        onProgress: (Double) -> Unit,
        onCompleted: (String) -> Unit,
        onError: (String, String?, Any?) -> Unit
    ) {
        // Cancel any ongoing transformation before starting a new one.
        cancelTransformation() // This cancels both the transformer and its progress simulation job.

        val transformationRunning = AtomicBoolean(false) // Tracks if the core transformation is active

        try {
            Log.d(TAG, "Transform: Starting setup for video '$inputVideoPath' with LUT asset '$lutAssetKey'")
            onProgress(0.0) // Initial progress: Setup phase started

            // Load LUT from assets
            val actualLutAssetPath = flutterAssets.getAssetFilePathByName(lutAssetKey)
            val lut = CubeParser.load(context, actualLutAssetPath) // This can throw IOException if LUT is invalid/not found
            val lutEffect = SingleColorLut.createFromCube(lut)
            val videoEffects = mutableListOf<androidx.media3.common.Effect>()
            videoEffects.add(lutEffect)

            // Apply a 1:1 aspect ratio crop.
            // This is a fixed behavior of this plugin version.
            // For more flexibility, these parameters could be exposed.
            val targetResolution = 1080 // Output resolution for the cropped square video
            val presentationEffect = Presentation.createForWidthAndHeight(
                targetResolution,
                targetResolution,
                Presentation.LAYOUT_SCALE_TO_FIT_WITH_CROP // Scales to fit the smaller dimension and crops the larger one
            )
            videoEffects.add(presentationEffect)

            val effects = Effects(
                /* audioEffects = */ emptyList(), // No audio effects applied in this version
                /* videoEffects = */ videoEffects.toList()
            )

            val mediaItem = MediaItem.fromUri(Uri.parse(inputVideoPath))
            val editedMediaItem = EditedMediaItem.Builder(mediaItem)
                .setEffects(effects)
                .build()

            val editedMediaItemSequence = EditedMediaItemSequence(listOf(editedMediaItem))
            // For concatenating multiple clips, add more EditedMediaItem to the list above,
            // or add more EditedMediaItemSequence to the compositionBuilder list.
            val composition = Composition.Builder(listOf(editedMediaItemSequence)).build()

            val outputVideoFile = File(context.cacheDir, "transformed_${UUID.randomUUID()}.mp4")
            Log.d(TAG, "Output video file will be: ${outputVideoFile.absolutePath}")

            val listener = object : Transformer.Listener {
                override fun onCompleted(
                    composition: Composition,
                    exportResult: ExportResult,
                ) {
                    transformationRunning.set(false)
                    progressJob?.cancel() // Stop dummy progress
                    Log.i(TAG, "Transformation completed successfully for ${outputVideoFile.name}. Output size: ${exportResult.fileSizeBytes} bytes.")
                    onProgress(1.0) // Final progress update
                    onCompleted(outputVideoFile.absolutePath)
                    currentTransformer = null // Clear the reference
                }

                override fun onError(
                    composition: Composition,
                    exportResult: ExportResult,
                    exception: ExportException
                ) {
                    transformationRunning.set(false)
                    progressJob?.cancel() // Stop dummy progress
                    Log.e(TAG, "Transformation error for ${outputVideoFile.name}: ${exception.errorCode} - ${exception.message}", exception)
                    onError(
                        "TRANSFORM_FAILED",
                        exception.localizedMessage ?: "Transformation failed with Media3 code ${exception.errorCode}",
                        exception.stackTraceToString()
                    )
                    currentTransformer = null // Clear the reference
                }
            }

            val transformerBuilder = Transformer.Builder(context)
                .setVideoMimeType(MimeTypes.VIDEO_H264) // Using H264 for broad compatibility. MimeTypes.VIDEO_MP4 is also an option.
                .addListener(listener)
            // For more advanced control, consider using:
            // .setEncoderFactory(...)
            // .setAudioEncoderFactory(...)
            // .setVideoEncoderFactory(...)
            // .setTransformationRequest(TransformationRequest.Builder().setFlattenForSlowMotion(true).build())

            val transformer = transformerBuilder.build()
            currentTransformer = transformer // Store for potential cancellation

            Log.i(TAG, "Starting Media3 transformation process...")
            onProgress(DUMMY_PROGRESS_START_VALUE) // Progress: Setup complete, actual transformation starting
            transformationRunning.set(true)
            transformer.start(composition, outputVideoFile.absolutePath)

            // Start dummy progress updates because Transformer's native progress is not straightforward.
            // This simulates progress while the transformation is running.
            progressJob = scope.launch {
                var currentSimulatedProgress = DUMMY_PROGRESS_START_VALUE
                val totalSteps = (DUMMY_PROGRESS_DURATION_MS / PROGRESS_UPDATE_INTERVAL_MS).toInt()
                if (totalSteps <= 0) return@launch // Avoid division by zero if duration is too short

                val increment = (DUMMY_PROGRESS_END_VALUE - DUMMY_PROGRESS_START_VALUE) / totalSteps

                while (isActive && transformationRunning.get() && currentSimulatedProgress < DUMMY_PROGRESS_END_VALUE) {
                    delay(PROGRESS_UPDATE_INTERVAL_MS)
                    if (!transformationRunning.get()) break // Stop if the main transformation has already completed or errored
                    currentSimulatedProgress += increment
                    // Ensure progress doesn't exceed DUMMY_PROGRESS_END_VALUE before actual completion/error
                    onProgress(currentSimulatedProgress.coerceAtMost(DUMMY_PROGRESS_END_VALUE))
                }
            }

        } catch (e: Exception) { // Catch exceptions during setup (e.g., LUT parsing, file access)
            transformationRunning.set(false)
            progressJob?.cancel()
            Log.e(TAG, "Exception during transform setup: ${e.message}", e)
            onError(
                "SETUP_FAILED",
                e.localizedMessage ?: "Setup for transformation failed due to an unexpected error.",
                e.stackTraceToString()
            )
            currentTransformer = null
        }
    }

    /**
     * Attempts to cancel the currently ongoing video transformation.
     * This will also cancel the dummy progress simulation.
     * The Transformer's listener (onCompleted or onError) should be triggered by the cancel call.
     */
    fun cancelTransformation() {
        progressJob?.cancel() // Stop the dummy progress job first
        progressJob = null
        if (currentTransformer != null) {
            Log.i(TAG, "Explicitly cancelling current Media3 transformation.")
            currentTransformer?.cancel() // Request cancellation of the Media3 Transformer
            // The listener's onError or onCompleted will be called, which then nullifies currentTransformer.
            // No need to nullify currentTransformer directly here as the listener handles it.
        } else {
            Log.d(TAG, "No active transformation to cancel.")
        }
    }
}
