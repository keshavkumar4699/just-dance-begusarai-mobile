package com.studiocrow.studio_crow

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Native helpers used by Studio Crow:
 *  - compressImage : scale a photo to max 640px and re-encode as JPEG (quality 85)
 *  - encodeJpeg    : encode a PNG image (from a Flutter-rendered widget) to a JPEG file
 *  - isWifi        : true when the device is on Wi-Fi (used by Wi-Fi-only backup)
 *  - shareToWhatsApp : open WhatsApp of a specific number with an attached image/text
 *
 * Extends FlutterFragmentActivity because local_auth's Android implementation
 * requires a FragmentActivity to show the system auth (face/fingerprint/PIN)
 * prompt.
 */
class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "studio_crow/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "compressImage" -> {
                        val src = call.argument<String>("path") ?: return@setMethodCallHandler result.error("bad", "no path", null)
                        result.success(compressImage(src))
                    }
                    "encodeJpeg" -> {
                        val png = call.argument<ByteArray>("png") ?: return@setMethodCallHandler result.error("bad", "no png", null)
                        val quality = call.argument<Int>("quality") ?: 88
                        result.success(encodeJpeg(png, quality))
                    }
                    "isWifi" -> {
                        result.success(isOnWifi())
                    }
                    "shareToWhatsApp" -> {
                        val path = call.argument<String>("path")
                        val number = call.argument<String>("number") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        result.success(shareToWhatsApp(path, number, text))
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("native", e.message, null)
            }
        }
    }

    private fun compressImage(src: String): String {
        val source = File(src)
        val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(src, opts)
        var scale = 1
        val maxDim = 640
        while (Math.max(opts.outWidth, opts.outHeight) / (scale * 2) >= maxDim) scale *= 2
        val decodeOpts = BitmapFactory.Options().apply {
            inSampleSize = scale
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        var bmp = BitmapFactory.decodeFile(src, decodeOpts)
        bmp = fitInside(bmp, maxDim)
        val out = File(cacheDir, "photo_${System.currentTimeMillis()}.jpg")
        FileOutputStream(out).use { fos ->
            bmp.compress(Bitmap.CompressFormat.JPEG, 85, fos)
        }
        bmp.recycle()
        return out.absolutePath
    }

    private fun encodeJpeg(png: ByteArray, quality: Int): String {
        val bmp = BitmapFactory.decodeByteArray(png, 0, png.size) ?: throw IllegalArgumentException("bad image")
        val out = File(cacheDir, "doc_${System.currentTimeMillis()}.jpg")
        FileOutputStream(out).use { fos ->
            bmp.compress(Bitmap.CompressFormat.JPEG, quality, fos)
        }
        bmp.recycle()
        return out.absolutePath
    }

    private fun fitInside(bmp: Bitmap, maxDim: Int): Bitmap {
        val w = bmp.width
        val h = bmp.height
        val largest = Math.max(w, h)
        if (largest <= maxDim) return bmp
        val scale = maxDim.toFloat() / largest.toFloat()
        val nw = Math.round(w * scale)
        val nh = Math.round(h * scale)
        val scaled = Bitmap.createScaledBitmap(bmp, nw, nh, true)
        if (scaled !== bmp) bmp.recycle()
        return scaled
    }

    private fun isOnWifi(): Boolean {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }

    /**
     * Shares an image + text to the WhatsApp chat of [number] (direct share).
     * Falls back to "com.whatsapp.w4b" (WhatsApp Business).
     * Returns false when WhatsApp is not installed.
     */
    private fun shareToWhatsApp(path: String?, number: String, text: String): Boolean {
        val waPackages = listOf("com.whatsapp", "com.whatsapp.w4b")
        val share = Intent(Intent.ACTION_SEND).apply {
            type = "image/jpeg"
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra(Intent.EXTRA_PHONE_NUMBER, number)
            if (path != null) {
                val f = File(path)
                val uri = FileProvider.getUriForFile(this@MainActivity, "$packageName.fileprovider", f)
                putExtra(Intent.EXTRA_STREAM, uri)
            }
        }
        for (pkg in waPackages) {
            val resolved = packageManager.queryIntentActivities(share, 0)
            if (resolved.any { it.activityInfo.packageName == pkg }) {
                share.setPackage(pkg)
                startActivity(share)
                return true
            }
        }
        return false
    }
}
