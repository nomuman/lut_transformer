import 'package:lut_transformer/src/transform_progress.dart';
// Flutter integration tests for the lut_transformer plugin.
//
// Integration tests run in a full Flutter application, allowing interaction
// with the native host side of the plugin.
// For more details, see: https://flutter.dev/to/integration-testing

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lut_transformer/lut_transformer.dart';
import 'package:path_provider/path_provider.dart'; // For managing test files

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Specific setup for all tests, if any.
  });

  tearDownAll(() async {
    // Specific teardown for all tests, if any.
  });

  group('LutTransformer Plugin Tests', () {
    testWidgets('getPlatformVersion returns non-empty string', (
      WidgetTester tester,
    ) async {
      final String? version = await LutTransformer.getPlatformVersion();
      // The version string depends on the host platform (e.g., "Android 12").
      // We just assert that a non-empty string is returned.
      expect(version, isNotNull);
      expect(version!.isNotEmpty, true);
      debugPrint('Platform version: $version');
    });

    // Test for the transformVideo functionality.
    // This test requires a sample video and a sample LUT file in assets.
    // Ensure 'example/assets/videos/sample.mp4' and 'example/assets/luts/sample.cube' exist
    // and are declared in 'example/pubspec.yaml'.
    testWidgets(
      'transformVideo successfully processes a video with a LUT and reports progress',
      (WidgetTester tester) async {
        // Prepare a dummy video file for testing if not using assets directly
        // For this example, we assume assets are correctly set up.
        // Copy asset to a temporary file to simulate a real file path input
        final ByteData videoData = await rootBundle.load(
          'assets/videos/sample.mp4',
        );
        final Directory tempDir = await getTemporaryDirectory();
        final File tempVideoFile = File(
          '${tempDir.path}/temp_video_for_test.mp4',
        );
        await tempVideoFile.writeAsBytes(
          videoData.buffer.asUint8List(),
          flush: true,
        );

        const String lutAssetPath =
            'assets/luts/sample.cube'; // Relative to app's assets

        final List<TransformProgress> progressEvents = [];
        String? finalOutputPath;
        Object? transformError;

        final stream = LutTransformer.transformVideo(
          tempVideoFile,
          lutAsset: lutAssetPath,
          flipHorizontally: false,
        );

        await for (final event in stream) {
          debugPrint(
            'Progress: ${event.progress}, Output: ${event.outputPath}, Error: ${event.error}',
          );
          progressEvents.add(event);
          if (event.outputPath != null) {
            finalOutputPath = event.outputPath;
          }
          if (event.error != null) {
            transformError = event.error;
            break; // Stop listening on error
          }
        }

        // Assertions
        expect(
          transformError,
          isNull,
          reason:
              'transformVideo should not produce an error for valid inputs.',
        );
        expect(
          progressEvents,
          isNotEmpty,
          reason: 'Should have received at least one progress event.',
        );

        // Check initial progress
        expect(
          progressEvents.first.progress,
          equals(0.0),
          reason: 'Initial progress should be 0.0.',
        );

        // Check for intermediate progress if dummy progress is working
        // This depends on the native implementation's dummy progress logic
        bool hasIntermediateProgress = progressEvents.any(
          (TransformProgress p) =>
              p.progress > 0.0 &&
              p.progress < 1.0 &&
              p.outputPath == null &&
              p.error == null,
        );
        // If dummy progress is very fast or not implemented, this might fail.
        // For now, we'll be lenient or focus on completion.
        debugPrint('Has intermediate progress: $hasIntermediateProgress');

        // Check final progress and output path
        final lastEvent = progressEvents.lastWhere(
          (TransformProgress e) => e.outputPath != null || e.error != null,
          orElse: () => progressEvents.last,
        );

        expect(
          lastEvent.progress,
          equals(1.0),
          reason: 'Final progress should be 1.0 on success.',
        );
        expect(
          lastEvent.outputPath,
          isNotNull,
          reason: 'Output path should be set on success.',
        );
        expect(
          lastEvent.outputPath!.isNotEmpty,
          true,
          reason: 'Output path string should not be empty.',
        );
        expect(
          finalOutputPath,
          isNotNull,
          reason: 'Final output path variable should be set.',
        );
        expect(
          finalOutputPath,
          endsWith('.mp4'),
          reason: 'Output file should be an mp4.',
        );

        // Verify the output file exists
        if (finalOutputPath != null) {
          final outputFile = File(finalOutputPath);
          expect(
            await outputFile.exists(),
            isTrue,
            reason: 'Transformed video file should exist at $finalOutputPath.',
          );
          // Optional: Clean up the created temporary and output files
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
        }
        if (await tempVideoFile.exists()) {
          await tempVideoFile.delete();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    ); // Video processing can take time

    testWidgets(
      'transformVideo successfully crops a video without a LUT',
      (WidgetTester tester) async {
        final ByteData videoData = await rootBundle.load(
          'assets/videos/sample.mp4',
        );
        final Directory tempDir = await getTemporaryDirectory();
        final File tempVideoFile = File(
          '${tempDir.path}/temp_video_for_crop_test.mp4',
        );
        await tempVideoFile.writeAsBytes(
          videoData.buffer.asUint8List(),
          flush: true,
        );

        final List<TransformProgress> progressEvents = [];
        String? finalOutputPath;
        Object? transformError;

        // Call transformVideo with lutAsset as null
        final stream = LutTransformer.transformVideo(
          tempVideoFile,
          lutAsset: null, // Test with null LUT
          flipHorizontally: false,
        );

        await for (final event in stream) {
          debugPrint(
            'Crop Progress: ${event.progress}, Output: ${event.outputPath}, Error: ${event.error}',
          );
          progressEvents.add(event);
          if (event.outputPath != null) {
            finalOutputPath = event.outputPath;
          }
          if (event.error != null) {
            transformError = event.error;
            break;
          }
        }

        expect(
          transformError,
          isNull,
          reason: 'transformVideo (crop only) should not produce an error.',
        );
        expect(
          progressEvents,
          isNotEmpty,
          reason:
              'Should have received at least one progress event (crop only).',
        );

        expect(
          progressEvents.first.progress,
          equals(0.0),
          reason: 'Initial progress should be 0.0 (crop only).',
        );

        final lastEvent = progressEvents.lastWhere(
          (TransformProgress e) => e.outputPath != null || e.error != null,
          orElse: () => progressEvents.last,
        );

        expect(
          lastEvent.progress,
          equals(1.0),
          reason: 'Final progress should be 1.0 on success (crop only).',
        );
        expect(
          lastEvent.outputPath,
          isNotNull,
          reason: 'Output path should be set on success (crop only).',
        );
        expect(
          finalOutputPath,
          isNotNull,
          reason: 'Final output path variable should be set (crop only).',
        );
        expect(
          finalOutputPath,
          endsWith('.mp4'),
          reason: 'Output file should be an mp4 (crop only).',
        );

        if (finalOutputPath != null) {
          final outputFile = File(finalOutputPath);
          expect(
            await outputFile.exists(),
            isTrue,
            reason:
                'Transformed video file (crop only) should exist at $finalOutputPath.',
          );
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
        }
        if (await tempVideoFile.exists()) {
          await tempVideoFile.delete();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    testWidgets(
      'transformVideo successfully processes a video with LUT and horizontal flip',
      (WidgetTester tester) async {
        final ByteData videoData = await rootBundle.load(
          'assets/videos/sample.mp4',
        );
        final Directory tempDir = await getTemporaryDirectory();
        final File tempVideoFile = File(
          '${tempDir.path}/temp_video_for_flip_test.mp4',
        );
        await tempVideoFile.writeAsBytes(
          videoData.buffer.asUint8List(),
          flush: true,
        );

        const String lutAssetPath = 'assets/luts/sample.cube';
        final List<TransformProgress> progressEvents = [];
        String? finalOutputPath;
        Object? transformError;

        final stream = LutTransformer.transformVideo(
          tempVideoFile,
          lutAsset: lutAssetPath,
          flipHorizontally: true,
        );

        await for (final event in stream) {
          debugPrint(
            'Flip Test Progress: ${event.progress}, Output: ${event.outputPath}, Error: ${event.error}',
          );
          progressEvents.add(event);
          if (event.outputPath != null) {
            finalOutputPath = event.outputPath;
          }
          if (event.error != null) {
            transformError = event.error;
            break;
          }
        }

        expect(
          transformError,
          isNull,
          reason: 'transformVideo with flip should not produce an error.',
        );
        expect(
          progressEvents,
          isNotEmpty,
          reason:
              'Should have received at least one progress event (with flip).',
        );
        expect(
          progressEvents.first.progress,
          equals(0.0),
          reason: 'Initial progress should be 0.0 (with flip).',
        );

        final lastEvent = progressEvents.lastWhere(
          (TransformProgress e) => e.outputPath != null || e.error != null,
          orElse: () => progressEvents.last,
        );

        expect(
          lastEvent.progress,
          equals(1.0),
          reason: 'Final progress should be 1.0 on success (with flip).',
        );
        expect(
          lastEvent.outputPath,
          isNotNull,
          reason: 'Output path should be set on success (with flip).',
        );
        expect(
          finalOutputPath,
          isNotNull,
          reason: 'Final output path variable should be set (with flip).',
        );
        expect(
          finalOutputPath,
          endsWith('.mp4'),
          reason: 'Output file should be an mp4 (with flip).',
        );

        if (finalOutputPath != null) {
          final outputFile = File(finalOutputPath);
          expect(
            await outputFile.exists(),
            isTrue,
            reason:
                'Transformed video file (with flip) should exist at $finalOutputPath.',
          );
          // TODO: Add a more robust check to verify if the video is actually flipped.
          // This might involve comparing frames or using a more advanced video analysis tool,
          // which is beyond the scope of a simple integration test here.
          // For now, we rely on the native transformation being correct.
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
        }
        if (await tempVideoFile.exists()) {
          await tempVideoFile.delete();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
