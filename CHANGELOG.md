## 1.1.0

* Added `lutIntensity` parameter to `transformVideo` method.
    * This allows adjusting the strength of the LUT effect from 0.0 (no effect) to 1.0 (full effect).
    * If `lutAsset` is provided and `lutIntensity` is null, it defaults to 1.0.
* Updated Android native code (`CubeParser.kt`, `VideoTransformer.kt`, `LutTransformerPlugin.kt`) to support LUT intensity.
* Updated Dart code (`lut_transformer.dart`) to include the `lutIntensity` parameter.
* Updated `README.md` to document the new `lutIntensity` feature.

## 1.0.4

* Modified `transformVideo` method:
    * Added `cropSquareSize` parameter to specify the size of the square to crop the video to.

## 1.0.3

* Improved video cropping:
    * The 1:1 aspect ratio crop now centers based on the video's shorter dimension, ensuring a more visually appealing centered square crop.

## 1.0.2

* Modified `transformVideo` method:
    * Added `flipHorizontally` parameter to flip the video horizontally. Defaults to `false`.

## 1.0.1

* Modified `transformVideo` method:
    * The `lutAsset` parameter is now nullable.
    * If `lutAsset` is null, the video will only be cropped to a square.
* Updated tests to cover the case where `lutAsset` is null.

## 1.0.0

* Initial release of the `lut_transformer` plugin.
* Supports applying 3D LUT (.cube) filters to videos on the Android platform.
* Features include:
    * Video transformation with LUT application.
    * 1:1 aspect ratio cropping during transformation.
    * Progress reporting for the transformation process.
* Includes an example application demonstrating plugin usage.
* Added integration tests for `getPlatformVersion` and `transformVideo`.
* Added unit tests for Android native code (CubeParser, LutTransformerPlugin).
