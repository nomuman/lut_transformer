package com.example.lut_transformer

import android.content.Context
import kotlin.math.roundToInt

/**
 * Parses a .cube LUT (Look-Up Table) file.
 */
object CubeParser {

    private val skipPrefixes = listOf("#", "TITLE", "DOMAIN_MIN", "DOMAIN_MAX")

    /**
     * Loads and parses a .cube LUT file from the app's assets.
     *
     * The .cube file format specifies color transformations. This parser reads the LUT size
     * and the RGB color values, then converts them into a 3D array structure
     * suitable for use with `SingleColorLut.createFromCube`.
     *
     * The resulting array is structured as `cube[rIndex][gIndex][bIndex]`,
     * where each element is an ARGB integer (alpha is set to opaque, 0xFF).
     * The order of iteration in the .cube file is typically Blue (slowest), Green, Red (fastest).
     *
     * @param context The Android [Context] used to access assets.
     * @param assetPath The path to the .cube file within the assets directory (e.g., "luts/my_lut.cube").
     * @return A 3D array representing the LUT: `Array<Array<IntArray>>`.
     * @throws java.io.IOException if the asset file cannot be opened or read.
     * @throws IllegalArgumentException if the LUT_3D_SIZE is not found, is invalid,
     *         or if the number of color values does not match the declared size.
     * @throws NumberFormatException if numeric values in the file cannot be parsed.
     */
    fun load(context: Context, assetPath: String): Array<Array<IntArray>> {
        val reader = context.assets.open(assetPath).bufferedReader()

        var size = 0
        val rawValues = mutableListOf<Float>()

        reader.forEachLine { lineRaw ->
            val line = lineRaw.trim()
            // Skip empty lines and comment lines or metadata lines
            if (line.isEmpty() || skipPrefixes.any { line.startsWith(it, ignoreCase = true) }) return@forEachLine

            if (line.startsWith("LUT_3D_SIZE", ignoreCase = true)) {
                // LUT_3D_SIZE is usually the last part of the line, e.g., "LUT_3D_SIZE 32"
                size = line.split(Regex("\\s+")).last().toInt()
            } else {
                // Assume lines with 3 float values are LUT data
                rawValues += line.split(Regex("\\s+")).map { it.toFloat() }
            }
        }

        require(size > 0) { "LUT_3D_SIZE not found or is invalid in $assetPath." }
        val expectedValues = size * size * size * 3 // 3 floats (R, G, B) per LUT entry
        require(rawValues.size == expectedValues) {
            "Expected $expectedValues float values for LUT size $size (got ${rawValues.size}) in $assetPath. " +
            "This means ${rawValues.size / 3} RGB triplets were found, but ${size * size * size} were expected."
        }

        // Create the 3D LUT array: cube[R][G][B]
        // The Media3 SingleColorLut expects this specific dimension order.
        val cube = Array(size) { Array(size) { IntArray(size) } }
        var idx = 0 // Index for iterating through rawValues

        // .cube files typically list values with Blue changing slowest, then Green, then Red fastest.
        // So, the outer loop is Blue, then Green, then Red.
        for (bIndex in 0 until size) {         // Blue dimension
            for (gIndex in 0 until size) {     // Green dimension
                for (rIndex in 0 until size) { // Red dimension
                    // Read RGB float values (typically 0.0 to 1.0)
                    val rFloat = rawValues[idx++]
                    val gFloat = rawValues[idx++]
                    val bFloat = rawValues[idx++]

                    // Convert to 8-bit integer values (0-255)
                    val r8 = (rFloat * 255f).roundToInt().coerceIn(0, 255)
                    val g8 = (gFloat * 255f).roundToInt().coerceIn(0, 255)
                    val b8 = (bFloat * 255f).roundToInt().coerceIn(0, 255)

                    // Combine into an ARGB integer (Alpha is fully opaque: 0xFF)
                    // The order for Media3 is cube[r][g][b]
                    cube[rIndex][gIndex][bIndex] = (0xFF shl 24) or (r8 shl 16) or (g8 shl 8) or b8
                }
            }
        }
        return cube
    }
}
