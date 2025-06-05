import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'src/transform_progress.dart';
import 'src/lut_transformer_platform_interface.dart';

/// Provides methods for transforming videos using LUTs.
class LutTransformer {
  static LutTransformerPlatform get _platform =>
      LutTransformerPlatform.instance;

  /// Retrieves the platform version.
  ///
  /// This method is primarily for testing and example purposes.
  static Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  /// Transforms a video using a LUT file and returns a stream of progress and the output file path.
  ///
  /// The [input] is the video file to be transformed.
  /// The [lutAsset] is the asset path of the LUT filter to apply. If null, the video will only be cropped to a square.
  /// The [flipHorizontally] flag indicates whether to flip the video horizontally. Defaults to `false`.
  /// The [cropSquareSize] specifies the size of the square to crop the video to. If null, no cropping is performed unless `lutAsset` is also null, in which case it defaults to the shorter dimension of the video.
  ///
  /// Returns a [Stream<TransformProgress>] that emits [TransformProgress] objects
  /// indicating the progress of the transformation ([TransformProgress.progress]),
  /// the final output path ([TransformProgress.outputPath]), or an error ([TransformProgress.error]).
  static Stream<TransformProgress> transformVideo(
    File input, {
    String? lutAsset,
    bool flipHorizontally = false,
    int? cropSquareSize,
  }) {
    return _platform.transformVideo(
      input,
      lutAsset: lutAsset,
      flipHorizontally: flipHorizontally,
      cropSquareSize: cropSquareSize,
    );
  }
}
