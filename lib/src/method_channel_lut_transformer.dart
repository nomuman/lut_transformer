import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'lut_transformer_platform_interface.dart';
import 'transform_progress.dart';

/// An implementation of [LutTransformerPlatform] that uses method channels.
class MethodChannelLutTransformer extends LutTransformerPlatform {
  static const MethodChannel _methodChannel = MethodChannel('lut_transformer/method');
  static const EventChannel _eventChannel = EventChannel('lut_transformer/event');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await _methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Stream<TransformProgress> transformVideo(
    File input, {
    String? lutAsset,
    bool flipHorizontally = false,
    int? cropSquareSize,
  }) {
    _methodChannel.invokeMethod<void>('transformVideo', {
      'inputPath': input.path,
      'lutAsset': lutAsset,
      'flipHorizontally': flipHorizontally,
      'cropSquareSize': cropSquareSize,
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
