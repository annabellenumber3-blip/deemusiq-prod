package oss.krtirtho.spotube

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val channelName = "deemusiq/integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // SHA-256 of the signing certificate (DER). Stable for every
                    // build signed with the same keystore; a repackaged APK must
                    // be re-signed with a different key, changing this value.
                    "certSha256" -> result.success(certSha256())
                    // SHA-256 of the installed base.apk on disk. Matches the file
                    // GitHub Actions published when the app is the unmodified CI
                    // artifact (direct-APK distribution).
                    "apkSha256" -> result.success(apkSha256())
                    else -> result.notImplemented()
                }
            }
    }

    private fun sha256Hex(bytes: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        return digest.joinToString("") { "%02x".format(it) }
    }

    @Suppress("DEPRECATION", "PackageManagerGetSignatures")
    private fun certSha256(): String? {
        return try {
            val pm = packageManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = pm.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES,
                )
                val signers = info.signingInfo?.apkContentsSigners ?: return null
                signers.firstOrNull()?.toByteArray()?.let { sha256Hex(it) }
            } else {
                val info = pm.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES,
                )
                info.signatures?.firstOrNull()?.toByteArray()?.let { sha256Hex(it) }
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun apkSha256(): String? {
        return try {
            val path = applicationInfo.sourceDir ?: return null
            val file = java.io.File(path)
            val digest = MessageDigest.getInstance("SHA-256")
            file.inputStream().use { input ->
                val buffer = ByteArray(8192)
                var read = input.read(buffer)
                while (read >= 0) {
                    digest.update(buffer, 0, read)
                    read = input.read(buffer)
                }
            }
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            null
        }
    }
}
