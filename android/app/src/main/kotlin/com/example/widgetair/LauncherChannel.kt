package com.example.widgetair

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

object LauncherChannel {

    // ─────────────────────────────────────────────────────────────
    // GET ALL INSTALLED APPS
    // Returns a list of maps: {name, packageName, isSystemApp}
    // Icons are fetched separately to keep this call fast
    // ─────────────────────────────────────────────────────────────
    fun getInstalledApps(context: Context, result: MethodChannel.Result) {
        try {
            val pm = context.packageManager
            val mainIntent = Intent(Intent.ACTION_MAIN, null).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }

            val resolvedApps: List<ResolveInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.queryIntentActivities(
                    mainIntent,
                    PackageManager.ResolveInfoFlags.of(0L)
                )
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(mainIntent, 0)
            }

            val appList = mutableListOf<Map<String, Any>>()

            for (resolveInfo in resolvedApps) {
                val packageName = resolveInfo.activityInfo.packageName

                // Skip our own app from the list
                if (packageName == context.packageName) continue

                val appName = resolveInfo.loadLabel(pm).toString()
                val isSystemApp = (resolveInfo.activityInfo.applicationInfo.flags and
                        android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0

                appList.add(
                    mapOf(
                        "name" to appName,
                        "packageName" to packageName,
                        "isSystemApp" to isSystemApp
                    )
                )
            }

            // Sort alphabetically by name
            val sorted = appList.sortedBy { (it["name"] as String).lowercase() }
            result.success(sorted)

        } catch (e: Exception) {
            result.error("GET_APPS_ERROR", e.message, null)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // GET APP ICON
    // Returns icon as PNG bytes — Flutter displays using Image.memory()
    // ─────────────────────────────────────────────────────────────
    fun getAppIcon(context: Context, packageName: String, result: MethodChannel.Result) {
        try {
            val pm = context.packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            result.success(stream.toByteArray())
        } catch (e: Exception) {
            result.error("ICON_ERROR", "Could not load icon for $packageName: ${e.message}", null)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // LAUNCH APP
    // ─────────────────────────────────────────────────────────────
    fun launchApp(context: Context, packageName: String, result: MethodChannel.Result) {
        try {
            val pm = context.packageManager
            val intent = pm.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(true)
            } else {
                result.error("LAUNCH_ERROR", "No launch intent found for $packageName", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", e.message, null)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // OPEN APP SETTINGS (for long press context menu)
    // ─────────────────────────────────────────────────────────────
    fun openAppSettings(context: Context, packageName: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // UNINSTALL APP (opens system uninstall dialog)
    // ─────────────────────────────────────────────────────────────
    fun uninstallApp(context: Context, packageName: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_DELETE).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("UNINSTALL_ERROR", e.message, null)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // HELPER — Convert any Drawable to Bitmap
    // Handles AdaptiveIconDrawable (Android 8+), BitmapDrawable, etc.
    // ─────────────────────────────────────────────────────────────
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }

        // AdaptiveIconDrawable — Android 8+ (API 26+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            drawable is AdaptiveIconDrawable
        ) {
            val bitmap = Bitmap.createBitmap(
                108, 108, Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            return bitmap
        }

        // Fallback for any other drawable type
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 108
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 108
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}