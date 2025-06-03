package com.example.lut_transformer

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

@RunWith(AndroidJUnit4::class)
class CubeParserTest {
    private lateinit var context: Context
    // Note: The test LUT files (test_correct.cube, test_invalid_size_mismatch.cube, test_no_size.cube)
    // are expected to be manually placed in the `src/androidTest/assets/` directory
    // for these tests to run correctly, as CubeParser.load uses context.assets.open().
    // The content for these files is defined below as string literals for reference.

    // Content for "test_correct.cube" (expected to be in src/androidTest/assets/test_correct.cube)
    private val testLutContent = """
    # Test LUT
    TITLE "Test 2x2x2 LUT"
    LUT_3D_SIZE 2
    DOMAIN_MIN 0.0 0.0 0.0
    DOMAIN_MAX 1.0 1.0 1.0
    # R G B
    0.0 0.0 0.0
    1.0 0.0 0.0
    0.0 1.0 0.0
    1.0 1.0 0.0
    0.0 0.0 1.0
    1.0 0.0 1.0
    0.0 1.0 1.0
    1.0 1.0 1.0
    """.trimIndent()

    // Content for "test_invalid_size_mismatch.cube" (expected to be in src/androidTest/assets/test_invalid_size_mismatch.cube)
    private val invalidLutContentSizeMismatch = """
    TITLE "Invalid LUT Size Mismatch"
    LUT_3D_SIZE 2
    0.0 0.0 0.0
    1.0 0.0 0.0
    """.trimIndent() // Not enough data points for LUT_3D_SIZE 2 (expects 2*2*2*3 = 24 floats)

    // Content for "test_no_size.cube" (expected to be in src/androidTest/assets/test_no_size.cube)
    private val invalidLutNoSize = """
    TITLE "Invalid LUT No Size"
    0.0 0.0 0.0
    1.0 0.0 0.0
    """.trimIndent()


    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext<Context>()
        // No dynamic file creation here; tests rely on pre-existing files in androidTest/assets/
    }

    @Test
    fun load_valid2x2x2Lut_parsesCorrectly() {
        // This test assumes "test_correct.cube" (with content from testLutContent)
        // has been placed in the `src/androidTest/assets/` directory.
        val cube = CubeParser.load(context, "test_correct.cube")

        assertEquals("LUT size should be 2", 2, cube.size)
        assertEquals("Dimension 2 of LUT should be 2", 2, cube[0].size)
        assertEquals("Dimension 3 of LUT should be 2", 2, cube[0][0].size)

        // Check a few values (ARGB format, Alpha = FF)
        // Values from testLutContent, order is B, G, R in file; access is cube[R][G][B]
        // File line: 0.0 0.0 0.0 (R=0, G=0, B=0) -> cube[0][0][0]
        assertEquals(0xFF000000.toInt(), cube[0][0][0])
        // File line: 1.0 0.0 0.0 (R=1, G=0, B=0) -> cube[1][0][0]
        assertEquals(0xFFFF0000.toInt(), cube[1][0][0])
        // File line: 0.0 1.0 0.0 (R=0, G=1, B=0) -> cube[0][1][0]
        assertEquals(0xFF00FF00.toInt(), cube[0][1][0])
        // File line: 1.0 1.0 1.0 (R=1, G=1, B=1) -> cube[1][1][1] (last value in the LUT)
        assertEquals(0xFFFFFFFF.toInt(), cube[1][1][1])
    }

    @Test
    fun load_lutWithSizeMismatch_throwsIllegalArgumentException() {
        // This test assumes "test_invalid_size_mismatch.cube"
        // has been placed in the `src/androidTest/assets/` directory.
        val exception = assertThrows(IllegalArgumentException::class.java) {
            CubeParser.load(context, "test_invalid_size_mismatch.cube")
        }
        // Based on invalidLutContentSizeMismatch (2 values * 3 floats = 6) vs expected (2*2*2*3 = 24)
        assertTrue(
            "Exception message should indicate mismatch. Was: ${exception.message}",
            exception.message?.contains("Expected 24 float values for LUT size 2 (got 6)") == true
        )
    }

    @Test
    fun load_lutWithNoSizeDeclaration_throwsIllegalArgumentException() {
        // This test assumes "test_no_size.cube"
        // has been placed in the `src/androidTest/assets/` directory.
        val exception = assertThrows(IllegalArgumentException::class.java) {
            CubeParser.load(context, "test_no_size.cube")
        }
        assertTrue(
            "Exception message should indicate LUT_3D_SIZE not found. Was: ${exception.message}",
            exception.message?.contains("LUT_3D_SIZE not found or is invalid") == true
        )
    }

    @Test
    fun load_nonExistentLut_throwsIOException() {
        // This will try to load a non-existent file from assets.
        assertThrows(IOException::class.java) {
            CubeParser.load(context, "non_existent_lut.cube")
        }
    }
}