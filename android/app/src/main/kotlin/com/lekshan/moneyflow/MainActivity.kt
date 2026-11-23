package com.lekshan.moneyflow

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private var csvResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.lekshan.moneyflow/export")
            .setMethodCallHandler { call, result ->
                if (call.method == "pickCsv") {
                    pickCsv(result)
                    return@setMethodCallHandler
                }
                if (call.method != "shareCsv") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val path = call.arguments as? String
                if (path == null) {
                    result.error("invalid_export", "Missing export file", null)
                    return@setMethodCallHandler
                }
                try {
                    val file = File(path)
                    val uri = FileProvider.getUriForFile(this, "$packageName.exports", file)
                    val share = Intent(Intent.ACTION_SEND).apply {
                        type = "text/csv"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        clipData = ClipData.newUri(contentResolver, file.name, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(share, "Export transactions"))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("export_failed", error.localizedMessage, null)
                }
            }
    }

    private fun pickCsv(result: MethodChannel.Result) {
        if (csvResult != null) {
            result.error("picker_busy", "A file picker is already open.", null)
            return
        }
        csvResult = result
        try {
            startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
            }, CSV_REQUEST)
        } catch (error: Exception) {
            csvResult = null
            result.error("picker_failed", "Couldn’t open the file picker.", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CSV_REQUEST) return
        val result = csvResult ?: return
        csvResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        Thread {
            try {
                val bytes = contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val count = input.read(buffer)
                        if (count == -1) break
                        if (output.size() + count > CSV_BYTE_LIMIT) {
                            throw IllegalArgumentException("Choose a CSV file smaller than 5 MB.")
                        }
                        output.write(buffer, 0, count)
                    }
                    output.toByteArray()
                } ?: error("Couldn’t open the CSV file.")
                runOnUiThread { result.success(bytes) }
            } catch (error: Exception) {
                val message = if (error is IllegalArgumentException) error.message
                    else "Couldn’t read the CSV file."
                runOnUiThread { result.error("read_failed", message, null) }
            }
        }.start()
    }

    private companion object {
        const val CSV_REQUEST = 4501
        const val CSV_BYTE_LIMIT = 5_000_000
    }
}
