package com.example.lut_transformer

import android.content.Context
import android.media.MediaMetadataRetriever
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream

@RunWith(AndroidJUnit4::class)
class VideoTransformerInstrumentedTest {
    @Test
    fun transformedVideo_isSquare() = runBlocking {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val inPath = copyTestAssetToCache(ctx, "sample.mp4")
        val outPath = VideoTransformer.transform(ctx, inPath, "sample")
        val retriever = MediaMetadataRetriever().apply { setDataSource(outPath) }
        val w = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)!!.toInt()
        val h = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)!!.toInt()
        assertEquals(w, h)
    }

    private fun copyTestAssetToCache(context: Context, assetName: String): String {
        val cacheDir = context.cacheDir
        val outFile = File(cacheDir, assetName)
        context.assets.open(assetName).use { input ->
            FileOutputStream(outFile).use { output ->
                input.copyTo(output)
            }
        }
        return outFile.absolutePath
    }
}