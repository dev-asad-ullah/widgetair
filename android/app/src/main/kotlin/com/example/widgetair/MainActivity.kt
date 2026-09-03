package com.example.widgetair

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Channel name must match exactly what Dart side uses
    private val CHANNEL = "com.example.widgetair/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register our platform channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "getInstalledApps" -> {
                    LauncherChannel.getInstalledApps(this, result)
                }

                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        LauncherChannel.launchApp(this, packageName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                    }
                }

                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        LauncherChannel.getAppIcon(this, packageName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                    }
                }

                "openAppSettings" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        LauncherChannel.openAppSettings(this, packageName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                    }
                }

                "uninstallApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        LauncherChannel.uninstallApp(this, packageName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "packageName is null", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}