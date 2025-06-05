import 'dart:io';
import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'transform_progress.dart';
import 'method_channel_lut_transformer.dart';

/// The interface that implementations of lut_transformer must extend.
abstract class LutTransformerPlatform extends PlatformInterface {
  LutTransformerPlatform() : super(token: _token);

  static final Object _token = Object();

  static LutTransformerPlatform _instance = MethodChannelLutTransformer();

  /// The default instance of [LutTransformerPlatform] to use.
  static LutTransformerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own class
  /// that extends [LutTransformerPlatform] when they register themselves.
  static set instance(LutTransformerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion();

  Stream<TransformProgress> transformVideo(
    File input, {
    String? lutAsset,
    bool flipHorizontally = false,
    int? cropSquareSize,
  });
}
