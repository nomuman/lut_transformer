/// Represents the progress of a video transformation.
class TransformProgress {
  /// The progress of the transformation, from 0.0 to 1.0.
  final double progress;

  /// The path to the transformed file. Set when the process is complete.
  final String? outputPath;

  /// The error that occurred during processing. Set if an error occurs.
  final Object? error;

  /// Creates a [TransformProgress] object.
  TransformProgress({required this.progress, this.outputPath, this.error});
}
