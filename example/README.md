# lut_transformer_example

This project demonstrates the usage of the `lut_transformer` Flutter plugin. It shows how to apply a 3D LUT filter to a video file and retrieve the platform version.

## How to Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/nomuman/lut_transformer.git
    cd lut_transformer/example
    ```

2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the example application:**
    ```bash
    flutter run
    ```

    Ensure you have an Android device or emulator connected.

## Plugin Usage Demonstrated

This example app demonstrates:

-   **Getting Platform Version:** Displays the current platform version using `LutTransformer.getPlatformVersion()`.
-   **Video Transformation:** (This part needs to be implemented in `main.dart` to fully demonstrate video transformation. Currently, the example app might not have a UI for selecting and transforming videos.)

    To fully test video transformation, you would typically:
    1.  Select a video file (e.g., using `image_picker`).
    2.  Specify a LUT asset (e.g., `assets/luts/sample.cube`).
    3.  Call `LutTransformer.transformVideo(inputFile, lutAsset: 'your_lut_asset_path')`.
    4.  Handle the returned output path to display or use the transformed video.

## Assets

This example project includes a sample `.cube` LUT file in `assets/luts/sample.cube`. You can add your own `.cube` files to the `assets/luts/` directory and reference them in your code.

## Getting Started with Flutter

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
