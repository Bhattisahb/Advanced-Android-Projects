package com.example.pos_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pos_app/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFile" -> {
                        val filePath = call.argument<String>("filePath")
                        val fileName = call.argument<String>("fileName")
                        
                        if (filePath != null && fileName != null) {
                            try {
                                shareFile(filePath, fileName)
                                result.success(true)
                            } catch (e: Exception) {
                                android.util.Log.e("ShareFile", "Error: ${e.message}")
                                result.error("SHARE_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INVALID_ARGS", "filePath and fileName are required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareFile(filePath: String, fileName: String) {
        try {
            val sourceFile = File(filePath)
            
            // Check if file exists
            if (!sourceFile.exists()) {
                throw Exception("File does not exist: $filePath")
            }

            android.util.Log.d("ShareFile", "Sharing file: $filePath (${sourceFile.length()} bytes)")

            // Copy to cache directory for sharing (FileProvider access)
            val cacheDir = cacheDir
            val shareFile = File(cacheDir, fileName)
            
            // Copy the file
            sourceFile.inputStream().use { input ->
                shareFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            // Create URI using FileProvider for Android 10+ compatibility
            val uri = FileProvider.getUriForFile(
                this,
                "${packageName}.fileprovider",
                shareFile
            )

            // Create share intent
            val shareIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = "application/json"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "POS App Backup: $fileName")
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            }

            android.util.Log.d("ShareFile", "Starting share chooser...")
            // Open share chooser
            startActivity(Intent.createChooser(shareIntent, "Share backup to:"))
        } catch (e: Exception) {
            android.util.Log.e("ShareFile", "Exception: ${e.message}", e)
            throw RuntimeException("Failed to share file: ${e.message}")
        }
    }
}

