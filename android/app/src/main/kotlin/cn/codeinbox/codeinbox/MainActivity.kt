package cn.codeinbox.codeinbox

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "codeinbox/badge")
            .setMethodCallHandler { call, result ->
                if (call.method == "setBadge") {
                    // Android launcher badges are OEM-specific; in-app badge still updates.
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
