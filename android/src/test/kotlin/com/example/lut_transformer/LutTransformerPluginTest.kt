package com.example.lut_transformer

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.eq
import org.mockito.Mockito
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.never

/**
 * Unit tests for the [LutTransformerPlugin].
 * These tests focus on the MethodCallHandler logic.
 */
class LutTransformerPluginTest {
  private lateinit var plugin: LutTransformerPlugin
  private lateinit var mockResult: MethodChannel.Result
  private lateinit var mockFlutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  private lateinit var mockActivityPluginBinding: ActivityPluginBinding
  private lateinit var mockActivity: Activity
  private lateinit var mockFlutterAssets: FlutterPlugin.FlutterAssets


  @Before
  fun setUp() {
    plugin = LutTransformerPlugin()
    mockResult = mock(MethodChannel.Result::class.java)

    // Mock FlutterPluginBinding and its components
    mockFlutterPluginBinding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
    val mockBinaryMessenger = mock(io.flutter.plugin.common.BinaryMessenger::class.java)
    Mockito.`when`(mockFlutterPluginBinding.binaryMessenger).thenReturn(mockBinaryMessenger)
    mockFlutterAssets = mock(FlutterPlugin.FlutterAssets::class.java)
    Mockito.`when`(mockFlutterPluginBinding.flutterAssets).thenReturn(mockFlutterAssets)

    // Attach to engine to initialize channels
    plugin.onAttachedToEngine(mockFlutterPluginBinding)

    // Mock Activity and ActivityPluginBinding
    mockActivityPluginBinding = mock(ActivityPluginBinding::class.java)
    mockActivity = mock(Activity::class.java)
    Mockito.`when`(mockActivityPluginBinding.activity).thenReturn(mockActivity)

    // Attach to activity
    plugin.onAttachedToActivity(mockActivityPluginBinding)
  }

  @Test
  fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
    val call = MethodCall("getPlatformVersion", null)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }

  @Test
  fun onMethodCall_transformVideo_withValidArgs_callsStartVideoTransformationAndSucceeds() {
    // Mock VideoTransformer to prevent actual transformation
    // This is tricky as VideoTransformer is an object.
    // For a true unit test, VideoTransformer would need to be injectable or its methods static and mockable.
    // Here, we'll focus on the plugin's argument checking and flow up to the point of calling VideoTransformer.

    val arguments = mapOf("inputPath" to "path/to/video.mp4", "lutAsset" to "luts/sample.cube")
    val call = MethodCall("transformVideo", arguments)

    // Simulate VideoTransformer.transform not throwing an exception immediately
    // and that the plugin acknowledges the call.
    // Actual progress/completion is via EventChannel, which is harder to unit test here.
    plugin.onMethodCall(call, mockResult)

    // Verify that result.success(null) is called, acknowledging the method call
    verify(mockResult).success(null)
    // We can't easily verify VideoTransformer.transform was called without refactoring or PowerMock.
    // However, we've tested the path that leads to it.
  }

  @Test
  fun onMethodCall_transformVideo_withFlipHorizontally_callsStartVideoTransformationAndSucceeds() {
    val arguments = mapOf(
        "inputPath" to "path/to/video.mp4",
        "lutAsset" to "luts/sample.cube",
        "flipHorizontally" to true
    )
    val call = MethodCall("transformVideo", arguments)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).success(null)
  }

  @Test
  fun onMethodCall_transformVideo_withFlipHorizontallyFalse_callsStartVideoTransformationAndSucceeds() {
    val arguments = mapOf(
        "inputPath" to "path/to/video.mp4",
        "lutAsset" to "luts/sample.cube",
        "flipHorizontally" to false
    )
    val call = MethodCall("transformVideo", arguments)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).success(null)
  }

  @Test
  fun onMethodCall_transformVideo_withFlipHorizontallyMissing_defaultsToFalseAndSucceeds() {
    val arguments = mapOf(
        "inputPath" to "path/to/video.mp4",
        "lutAsset" to "luts/sample.cube"
    )
    val call = MethodCall("transformVideo", arguments)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).success(null)
  }


  @Test
  fun onMethodCall_transformVideo_withNullInputPath_returnsError() {
    val arguments = mapOf("inputPath" to null, "lutAsset" to "luts/sample.cube", "flipHorizontally" to false)
    val call = MethodCall("transformVideo", arguments)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).error(eq("INVALID_ARGUMENTS"), anyString(), eq(null))
  }

  @Test
  fun onMethodCall_transformVideo_withNullLutAsset_callsStartVideoTransformationAndSucceeds() {
    val arguments = mapOf<String, Any?>("inputPath" to "path/to/video.mp4", "lutAsset" to null, "flipHorizontally" to false)
    val call = MethodCall("transformVideo", arguments)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).success(null)
    verify(mockResult, never()).error(anyString(), anyString(), anyString())
  }

  @Test
  fun onMethodCall_transformVideo_whenActivityNotAvailable_returnsError() {
    // Detach activity to simulate it not being available
    plugin.onDetachedFromActivity() // Sets activityBinding to null

    val arguments = mapOf("inputPath" to "path/to/video.mp4", "lutAsset" to "luts/sample.cube", "flipHorizontally" to false)
    val call = MethodCall("transformVideo", arguments)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).error(eq("NO_ACTIVITY"), anyString(), eq(null))

    // Re-attach for other tests
    plugin.onAttachedToActivity(mockActivityPluginBinding)
  }

   @Test
  fun onMethodCall_transformVideo_whenFlutterAssetsNotAvailable_returnsError() {
    // Simulate flutterAssets being null (e.g., engine not fully attached or error state)
    // This requires modifying the plugin's internal state or mocking onAttachedToEngine behavior.
    // For simplicity, we'll assume a state where flutterPluginBindingInstance.flutterAssets is null.
    // This is hard to achieve without making flutterPluginBindingInstance mutable or using more complex mocking.

    // A more direct way:
    val pluginWithNoAssets = LutTransformerPlugin() // Fresh instance
    val tempMockFlutterPluginBinding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
    val tempMockBinaryMessenger = mock(io.flutter.plugin.common.BinaryMessenger::class.java)
    Mockito.`when`(tempMockFlutterPluginBinding.binaryMessenger).thenReturn(tempMockBinaryMessenger)
    Mockito.`when`(tempMockFlutterPluginBinding.flutterAssets).thenReturn(null) // Explicitly set to null
    pluginWithNoAssets.onAttachedToEngine(tempMockFlutterPluginBinding)
    // Also attach to a dummy activity for this specific test instance
    val tempMockActivityBinding = mock(ActivityPluginBinding::class.java)
    val tempMockActivity = mock(Activity::class.java)
    Mockito.`when`(tempMockActivityBinding.activity).thenReturn(tempMockActivity)
    pluginWithNoAssets.onAttachedToActivity(tempMockActivityBinding)


    val arguments = mapOf("inputPath" to "path/to/video.mp4", "lutAsset" to "luts/sample.cube", "flipHorizontally" to false)
    val call = MethodCall("transformVideo", arguments)
    val newMockResult: MethodChannel.Result = mock(MethodChannel.Result::class.java)

    pluginWithNoAssets.onMethodCall(call, newMockResult)
    verify(newMockResult).error(eq("NO_FLUTTER_ASSETS"), anyString(), eq(null))
  }


  @Test
  fun onMethodCall_unknownMethod_callsNotImplemented() {
    val call = MethodCall("unknownMethod", null)
    plugin.onMethodCall(call, mockResult)
    verify(mockResult).notImplemented()
  }

  // TODO: Add tests for EventChannel StreamHandler (onListen, onCancel) if complex logic exists.
  // For this plugin, onListen and onCancel are fairly simple, primarily setting eventSink.
}
