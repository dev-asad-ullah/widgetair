import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Singleton service that handles all communication with Kotlin native code.
/// Every call to Android goes through here — nothing talks to the platform
/// channel directly except this file.
class PlatformChannelService {
  PlatformChannelService._internal();
  static final PlatformChannelService instance = PlatformChannelService._internal();

  static const MethodChannel _channel = MethodChannel('com.example.widgetair/launcher');

  // ─────────────────────────────────────────────────────────────
  // GET ALL INSTALLED APPS
  // Returns raw list from Kotlin — parsed into AppInfo by provider
  // ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getInstalledApps');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get installed apps: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GET APP ICON AS BYTES
  // Returns PNG bytes — use with Image.memory() in Flutter
  // ─────────────────────────────────────────────────────────────
  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final Uint8List? bytes = await _channel.invokeMethod(
        'getAppIcon',
        {'packageName': packageName},
      );
      return bytes;
    } on PlatformException {
      // Return null on failure — UI handles the fallback icon
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LAUNCH APP
  // ─────────────────────────────────────────────────────────────
  Future<bool> launchApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod(
        'launchApp',
        {'packageName': packageName},
      );
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to launch $packageName: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // OPEN APP SETTINGS
  // ─────────────────────────────────────────────────────────────
  Future<bool> openAppSettings(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod(
        'openAppSettings',
        {'packageName': packageName},
      );
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to open settings for $packageName: ${e.message}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UNINSTALL APP
  // ─────────────────────────────────────────────────────────────
  Future<bool> uninstallApp(String packageName) async {
    try {
      final bool result = await _channel.invokeMethod(
        'uninstallApp',
        {'packageName': packageName},
      );
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to uninstall $packageName: ${e.message}');
    }
  }
}