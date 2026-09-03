import 'dart:typed_data';

/// Represents a single installed app on the device.
/// Icons are stored as raw bytes so Flutter can display them with Image.memory().
class AppInfo {
  final String name;
  final String packageName;
  final bool isSystemApp;

  // Icon bytes — null until loaded (lazy loading for performance)
  Uint8List? iconBytes;

  AppInfo({
    required this.name,
    required this.packageName,
    required this.isSystemApp,
    this.iconBytes,
  });

  // ─────────────────────────────────────────────────────────────
  // Create from the raw map returned by Kotlin
  // ─────────────────────────────────────────────────────────────
  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      name: map['name'] as String,
      packageName: map['packageName'] as String,
      isSystemApp: map['isSystemApp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packageName': packageName,
      'isSystemApp': isSystemApp,
    };
  }

  // Two AppInfo objects are equal if they have the same package name
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;

  @override
  String toString() => 'AppInfo(name: $name, package: $packageName)';
}