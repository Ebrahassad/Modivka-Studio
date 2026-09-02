package com.ebrahassad.watermark_pro

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.os.StrictMode
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "watermark_pro/folder"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        StrictMode.setVmPolicy(
            StrictMode.VmPolicy.Builder().build()
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "openFolder") {

                val path = call.argument<String>("path")

                if (path.isNullOrBlank()) {
                    result.error(
                        "INVALID_PATH",
                        "Folder path is empty",
                        null
                    )
                    return@setMethodCallHandler
                }

                try {
                    val folder = File(path)

                    if (!folder.exists() || !folder.isDirectory) {
                        result.error(
                            "FOLDER_NOT_FOUND",
                            "Folder does not exist: $path",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val opened = openFolderPreciseLocation(folder) ||
                        openFolderLegacyFallback(folder)

                    if (opened) {
                        result.success(true)
                    } else {
                        result.error(
                            "OPEN_FOLDER_ERROR",
                            "No app available to open the folder",
                            null
                        )
                    }

                } catch (e: Exception) {
                    result.error(
                        "OPEN_FOLDER_ERROR",
                        e.message ?: "Unable to open folder",
                        null
                    )
                }

            } else {
                result.notImplemented()
            }
        }
    }

    private fun openFolderPreciseLocation(folder: File): Boolean {
        return try {
            val externalRoot =
                Environment.getExternalStorageDirectory().absolutePath

            val folderPath = folder.absolutePath

            if (!folderPath.startsWith(externalRoot)) {
                return false
            }

            var relative = folderPath.removePrefix(externalRoot)

            if (relative.startsWith("/")) {
                relative = relative.substring(1)
            }

            val docId =
                if (relative.isEmpty()) {
                    "primary:"
                } else {
                    "primary:$relative"
                }

            val uri = DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents",
                docId
            )

            val intents = listOf(
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(
                        uri,
                        "vnd.android.document/directory"
                    )
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                },
                Intent(Intent.ACTION_VIEW).apply {
                    data = uri
                    addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    )
                }
            )

            for (intent in intents) {
                try {
                    if (intent.resolveActivity(packageManager) != null) {
                        startActivity(intent)
                        return true
                    }
                } catch (_: Exception) {
                }
            }

            false
        } catch (_: Exception) {
            false
        }
    }

    private fun openFolderLegacyFallback(folder: File): Boolean {
        return try {
            val uri = Uri.fromFile(folder)

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(
                    uri,
                    "resource/folder"
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }
}
