package app.mentalmetal.wharfwod

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Analytics flag test traffic (`is_test`): Play pre-launch devices
        // and emulators (the ship gates and capture runs) never read as real
        // users. Both answers are instant, local reads, so `detect` and
        // `detectLocal` are the same on Android.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.mentalmetal.wharfwod/test_device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "detect", "detectLocal" -> result.success(testReason())
                    else -> result.notImplemented()
                }
            }
    }

    /** Play pre-launch reports run on Firebase Test Lab, which sets a system
     *  flag; emulators carry generic build properties. */
    private fun testReason(): String {
        val testLab = Settings.System.getString(contentResolver, "firebase.test.lab")
        if (testLab == "true") return "firebase_test_lab"
        return if (isEmulator()) "emulator" else "none"
    }

    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val product = Build.PRODUCT.lowercase()
        val hardware = Build.HARDWARE.lowercase()
        return fingerprint.startsWith("generic") ||
            fingerprint.startsWith("unknown") ||
            fingerprint.contains("emulator") ||
            fingerprint.contains("sdk_gphone") ||
            model.contains("google_sdk") ||
            model.contains("emulator") ||
            model.contains("android sdk built for") ||
            model.contains("sdk_gphone") ||
            product.startsWith("sdk") ||
            product.contains("emulator") ||
            product.contains("simulator") ||
            product.contains("vbox86") ||
            hardware.contains("goldfish") ||
            hardware.contains("ranchu") ||
            hardware.contains("cutf") ||
            Build.MANUFACTURER.lowercase().contains("genymotion") ||
            (Build.BRAND.lowercase().startsWith("generic") &&
                Build.DEVICE.lowercase().startsWith("generic"))
    }
}
