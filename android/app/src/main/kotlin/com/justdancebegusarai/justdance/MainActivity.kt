package com.justdancebegusarai.justdance

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FlutterFragmentActivity is required by local_auth for biometric prompts.
class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Direct "share image to a specific WhatsApp number" intent.
        // No extra Dart packages — plain Android ACTION_SEND with a jid extra.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "studio_crow/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareToWhatsApp" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val path = call.argument<String>("path") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val type = call.argument<String>("type") ?: "image/jpeg"
                        try {
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.fileprovider", File(path)
                            )
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                this.type = type
                                putExtra(Intent.EXTRA_STREAM, uri)
                                putExtra(Intent.EXTRA_TEXT, text)
                                putExtra("jid", "$phone@s.whatsapp.net")
                                setPackage("com.whatsapp")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
