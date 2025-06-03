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
