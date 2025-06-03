# lut_transformer

[![pub version](https://img.shields.io/pub/v/lut_transformer.svg)](https://pub.dev/packages/lut_transformer)
<!-- TODO: Add CI badge e.g. [![CI](https://github.com/nomuman/lut_transformer/actions/workflows/ci.yaml/badge.svg)](https://github.com/nomuman/lut_transformer/actions/workflows/ci.yaml) -->

A Flutter plugin for applying 3D LUT (Look-Up Table) filters to videos on the **Android** platform. This plugin allows you to transform the colors of your videos using `.cube` LUT files. It also applies a 1:1 aspect ratio crop to the output video.

## Features

- Apply `.cube` LUT files to videos.
- Reports transformation progress.
- Output video is cropped to a 1:1 aspect ratio (e.g., 1080x1080).
- Option to flip the video horizontally.
- Currently supports Android only.

## Platform Support

| Android | iOS     | Web     | macOS   | Windows | Linux   |
| :------ | :------ | :------ | :------ | :------ | :------ |
| ✅      | ❌      | ❌      | ❌      | ❌      | ❌      |

iOS and other platform support may be considered in the future.

## Getting Started

### Prerequisites

- Flutter SDK: Version `>=3.32.0` (as per `pubspec.yaml`)
- Dart SDK: Version `>=3.8.0 <4.0.0` (as per `pubspec.yaml`)

### Installation

Add `lut_transformer` to your `pubspec.yaml` file:

```yaml
dependencies:
  lut_transformer: ^1.0.0 # Use the latest version from pub.dev
```

Then, run `flutter pub get` to install the package.

### Android Setup

No specific additional setup is required for Android beyond the standard Flutter project setup. Ensure your project meets the minimum Android SDK requirements if any are imposed by the underlying Media3 library (typically API level 21 or higher).

### iOS Setup

iOS is not currently supported.

## Usage

### Importing the plugin

```dart
import 'package:lut_transformer/lut_transformer.dart';
import 'dart:io'; // For File objects
// Import 'package:flutter/services.dart' for PlatformException if you need to specifically catch it.
```

### Transforming a Video

To transform a video, use the static method `LutTransformer.transformVideo`. You need to provide the input video `File`, optionally the asset path to your `.cube` LUT file, and an optional boolean `flipHorizontally` (defaults to `false`) to indicate if the video should be flipped horizontally. If `lutAsset` is `null`, the video will only be cropped to a square (and potentially flipped).

The method returns a `Stream<TransformProgress>` which emits progress updates and the final result (output path or error).

1.  **Ensure your LUT file is in assets:**
    Add your `.cube` file to your project's assets folder (e.g., `assets/luts/my_custom_lut.cube`) and declare it in your `pubspec.yaml`:

    ```yaml
    flutter:
      assets:
        - assets/luts/my_custom_lut.cube
        # Add other assets here
    ```

2.  **Call `transformVideo` and listen to the stream:**

    ```dart
    Future<void> applyLutToVideo(File videoFile, String? lutAssetPath, bool shouldFlip) async {
      final Stream<TransformProgress> progressStream = LutTransformer.transformVideo(
        videoFile,
        lutAsset: lutAssetPath, // e.g., 'assets/luts/my_custom_lut.cube' or null
        flipHorizontally: shouldFlip,
      );

      await for (final TransformProgress progressData in progressStream) {
        print('Video transformation progress: ${progressData.progress * 100}%');

        if (progressData.error != null) {
          print('Error during transformation: ${progressData.error!.code}');
          print('Error message: ${progressData.error!.message}');
          // Handle error (e.g., show a message to the user)
          break; // Stop listening if an error occurs
        }

        if (progressData.outputPath != null) {
          print('Video transformation complete! Output path: ${progressData.outputPath}');
          // Use the outputPath to access the transformed video file
          // e.g., display it, save it, upload it.
          File transformedVideo = File(progressData.outputPath!);
          // ... do something with transformedVideo ...
        }
      }
    }

    // Example usage:
    // File myVideo = File('path/to/your/input_video.mp4');
    // String myLut = 'assets/luts/my_custom_lut.cube';
    // bool flip = true;
    // await applyLutToVideo(myVideo, myLut, flip);
    ```

### `TransformProgress` Class

The `TransformProgress` object emitted by the stream has the following properties:

-   `double progress`: The transformation progress from 0.0 (0%) to 1.0 (100%).
-   `String? outputPath`: The file path of the transformed video. This is non-null only when the transformation is successfully completed (i.e., progress is 1.0 and no error).
-   `PlatformException? error`: If an error occurs during transformation, this will contain the `PlatformException` with error details. It's null if no error occurred.

### Getting the Platform Version (for debugging)

You can get the underlying platform version (e.g., "Android 12") using `getPlatformVersion`. This is mostly for debugging or informational purposes.

```dart
String? platformVersion = await LutTransformer.getPlatformVersion();
print('Running on: $platformVersion');
```

## Example Application

An example application demonstrating the use of `lut_transformer` can be found in the `example/` directory of this package. Run it to see the plugin in action.

## Testing

This plugin includes unit and integration tests.

### Running Integration Tests (Flutter)

Navigate to the `example` directory and run:

```bash
flutter test integration_test
```

### Running Unit Tests (Android Native - Kotlin)

To run the native Android (Kotlin) unit tests for components like `CubeParser`:

1.  **Prepare Test Assets (Important for `CubeParserTest`):**
    The `CubeParserTest.kt` requires specific `.cube` files to be present in the `example/android/src/androidTest/assets/` directory. You'll need to manually create these files:
    *   `example/android/src/androidTest/assets/test_correct.cube`
    *   `example/android/src/androidTest/assets/test_invalid_size_mismatch.cube`
    *   `example/android/src/androidTest/assets/test_no_size.cube`
    The content for these files can be found within the `CubeParserTest.kt` file itself (e.g., `testLutContent` string).

2.  **Run Gradle Task:**
    Navigate to the `android/` directory of the plugin (not the example's android directory) and run:
    ```bash
    ./gradlew testDebugUnitTest
    ```
    Or, if you are in the `example/android/` directory:
    ```bash
    ./gradlew :lut_transformer:testDebugUnitTest
    ```
    (The exact command might vary slightly based on your project structure if it's part of a larger mono-repo).
    Alternatively, run them directly from Android Studio.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please feel free to:

-   Open an issue on the [GitHub repository](https://github.com/nomuman/lut_transformer/issues). <!-- TODO: Replace with actual URL -->
-   Submit a pull request with your changes.

Please ensure that your contributions adhere to the project's coding style and that all tests pass.

## License

This plugin is released under the **MIT License**. See the [LICENSE](LICENSE) file for more details.
