package com.example.music_player

import android.app.RecoverableSecurityException
import android.content.ActivityNotFoundException
import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceFragmentActivity() {
    private val channelName = "com.example.music_player/file_actions"
    private var pendingDeleteResult: MethodChannel.Result? = null
    private val deleteRequestCode = 9417

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == deleteRequestCode) {
            val success = resultCode == RESULT_OK
            pendingDeleteResult?.success(if (success) "deleted" else "cancelled")
            pendingDeleteResult = null
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deleteMedia" -> {
                        val path = call.argument<String>("path")
                        val mediaId = call.argument<Number>("mediaId")?.toInt()
                        if (path.isNullOrBlank()) {
                            result.success("failed")
                        } else {
                            deleteMediaFileAsync(path, mediaId, result)
                        }
                    }
                    "openAllFilesAccessSettings" -> {
                        result.success(openAllFilesAccessSettings())
                    }
                    "hasAllFilesAccess" -> {
                        result.success(hasAllFilesAccess())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }
    }

    private fun openAllFilesAccessSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent =
                    Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Fall through.
            }
        }
        return try {
            val intent =
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun audioCollectionUri(): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            @Suppress("DEPRECATION")
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }

    private fun resolveAudioContentUri(path: String, mediaId: Int?): Uri? {
        if (mediaId != null && mediaId > 0) {
            return ContentUris.withAppendedId(audioCollectionUri(), mediaId.toLong())
        }

        val projection = arrayOf(MediaStore.Audio.Media._ID)
        val selection = "${MediaStore.Audio.Media.DATA} = ?"
        contentResolver
            .query(audioCollectionUri(), projection, selection, arrayOf(path), null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idIndex = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
                    if (idIndex >= 0) {
                        val id = cursor.getLong(idIndex)
                        return ContentUris.withAppendedId(audioCollectionUri(), id)
                    }
                }
            }

        val fileName = File(path).name
        if (fileName.isNotEmpty()) {
            contentResolver
                .query(
                    audioCollectionUri(),
                    projection,
                    "${MediaStore.Audio.Media.DISPLAY_NAME} = ?",
                    arrayOf(fileName),
                    null,
                )
                ?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val idIndex = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
                        if (idIndex >= 0) {
                            val id = cursor.getLong(idIndex)
                            val uri = ContentUris.withAppendedId(audioCollectionUri(), id)
                            if (pathMatchesMediaEntry(path, uri)) return uri
                        }
                    }
                }
        }

        return null
    }

    private fun pathMatchesMediaEntry(path: String, mediaUri: Uri): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
        val projection = arrayOf(MediaStore.Audio.Media.DATA, MediaStore.Audio.Media.RELATIVE_PATH)
        contentResolver.query(mediaUri, projection, null, null, null)?.use { cursor ->
            if (!cursor.moveToFirst()) return false
            val dataIndex = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            if (dataIndex >= 0) {
                val data = cursor.getString(dataIndex)
                if (!data.isNullOrBlank() && data == path) return true
            }
            val relIndex = cursor.getColumnIndex(MediaStore.Audio.Media.RELATIVE_PATH)
            if (relIndex >= 0) {
                val rel = cursor.getString(relIndex) ?: ""
                if (rel.endsWith(File(path).name)) return true
            }
        }
        return false
    }

    private fun deleteMediaFileAsync(
        path: String,
        mediaId: Int?,
        result: MethodChannel.Result,
    ) {
        val contentUri = resolveAudioContentUri(path, mediaId)

        if (hasAllFilesAccess()) {
            val deletedOnDisk = deleteFileOnDisk(path)
            if (contentUri != null) {
                try {
                    contentResolver.delete(contentUri, null, null)
                } catch (e: Exception) {
                    // Ignore — file may already be removed from index.
                }
            }
            if (deletedOnDisk || !File(path).exists()) {
                result.success("deleted")
                return
            }
        }

        if (contentUri != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (launchSystemDeleteRequest(contentUri, result)) return
            }

            try {
                val deleted = contentResolver.delete(contentUri, null, null)
                if (deleted > 0) {
                    deleteFileOnDisk(path)
                    result.success("deleted")
                    return
                }
            } catch (e: RecoverableSecurityException) {
                if (launchDeleteConsent(contentUri, e, result)) return
            } catch (e: SecurityException) {
                if (launchSystemDeleteRequest(contentUri, result)) return
            }
        }

        if (deleteFileOnDisk(path)) {
            result.success("deleted")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !hasAllFilesAccess()) {
            result.success("need_all_files_access")
            return
        }

        result.success("failed")
    }

    private fun launchDeleteConsent(
        uri: Uri,
        exception: RecoverableSecurityException,
        result: MethodChannel.Result,
    ): Boolean {
        return try {
            startDeleteIntentSender(exception.userAction.actionIntent.intentSender, result)
            true
        } catch (e: Exception) {
            launchSystemDeleteRequest(uri, result)
        }
    }

    private fun launchSystemDeleteRequest(
        uri: Uri,
        result: MethodChannel.Result,
    ): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        return try {
            val request = MediaStore.createDeleteRequest(contentResolver, listOf(uri))
            startDeleteIntentSender(request.intentSender, result)
            true
        } catch (e: Exception) {
            pendingDeleteResult = null
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun startDeleteIntentSender(
        intentSender: android.content.IntentSender,
        result: MethodChannel.Result,
    ) {
        pendingDeleteResult = result
        startIntentSenderForResult(intentSender, deleteRequestCode, null, 0, 0, 0, null)
    }

    private fun deleteFileOnDisk(path: String): Boolean {
        val file = File(path)
        return file.exists() && file.delete()
    }
}
