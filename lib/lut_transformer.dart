import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

/// Represents the progress of a video transformation.
class TransformProgress {
  /// The progress of the transformation, from 0.0 to 1.0.
  final double progress;

  /// The path to the transformed file. Set when the process is complete.
  final String? outputPath;

  /// The error that occurred during processing. Set if an error occurs.
  final PlatformException? error;

  /// Creates a [TransformProgress] object.
  TransformProgress({required this.progress, this.outputPath, this.error});
}

/// Provides methods for transforming videos using LUTs.
class LutTransformer {
  static const MethodChannel _methodChannel = MethodChannel(
    'lut_transformer/method',
  );
  static const EventChannel _eventChannel = EventChannel(
    'lut_transformer/event',
  );

  /// Retrieves the platform version.
  ///
  /// This method is primarily for testing and example purposes.
  static Future<String?> getPlatformVersion() async {
    final String? version = await _methodChannel.invokeMethod(
      'getPlatformVersion',
    );
    return version;
  }

  /// Transforms a video using a LUT file and returns a stream of progress and the output file path.
  ///
  /// The [input] is the video file to be transformed.
  /// The [lutAsset] is the asset path of the LUT filter to apply. If null, the video will only be cropped to a square.
  ///
  /// Returns a [Stream<TransformProgress>] that emits [TransformProgress] objects
  /// indicating the progress of the transformation ([TransformProgress.progress]),
  /// the final output path ([TransformProgress.outputPath]), or an error ([TransformProgress.error]).
  static Stream<TransformProgress> transformVideo(
    File input, {
    String? lutAsset,
  }) {
    // Request the native side to start processing.
    // This call completes immediately, and the actual processing occurs in the background.
    // Progress is reported via the EventChannel.
    _methodChannel.invokeMethod<void>('transformVideo', {
      'inputPath': input.path,
      'lutAsset': lutAsset,
    });

    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        final progress = (event['progress'] as num?)?.toDouble() ?? 0.0;
        final outputPath = event['outputPath'] as String?;
        final errorCode = event['errorCode'] as String?;
        final errorMessage = event['errorMessage'] as String?;
        final errorDetails = event['errorDetails'];

        if (errorCode != null) {
          return TransformProgress(
            progress: progress,
            error: PlatformException(
              code: errorCode,
              message: errorMessage,
              details: errorDetails,
            ),
          );
        }
        return TransformProgress(progress: progress, outputPath: outputPath);
      }
      // Unexpected event format
      return TransformProgress(
        progress: 0.0,
        error: PlatformException(
          code: 'UNKNOWN_EVENT_TYPE',
          message: 'Received unknown event type: ${event.runtimeType}',
        ),
      );
    });
  }
}
