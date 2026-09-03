import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/app_info.dart';
import '../core/services/platform_channel_service.dart';

// ─────────────────────────────────────────────────────────────
// RAW APP LIST — loads all installed apps once
// ─────────────────────────────────────────────────────────────
final appListProvider = FutureProvider<List<AppInfo>>((ref) async {
  final rawList = await PlatformChannelService.instance.getInstalledApps();
  return rawList.map((map) => AppInfo.fromMap(map)).toList();
});

// ─────────────────────────────────────────────────────────────
// SEARCH QUERY — tracks what user types in search bar
// Uses modern Riverpod 3.x Notifier style
// ─────────────────────────────────────────────────────────────
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

// ─────────────────────────────────────────────────────────────
// FILTERED APP LIST — reacts to search query automatically
// Uses whenData to avoid manually wrapping AsyncValue
// ─────────────────────────────────────────────────────────────
final filteredAppListProvider = Provider<AsyncValue<List<AppInfo>>>((ref) {
  final appsAsync = ref.watch(appListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return appsAsync;

  return appsAsync.whenData(
    (apps) => apps
        .where(
          (app) =>
              app.name.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query),
        )
        .toList(),
  );
});

// ─────────────────────────────────────────────────────────────
// ICON LOADER — loads a single app icon on demand
// Uses ref.watch on appListProvider for cache lookup
// Does not mutate AppInfo directly — returns bytes only
// ─────────────────────────────────────────────────────────────
final appIconProvider =
    FutureProvider.family<Uint8List?, String>((ref, packageName) async {
  // Check cache from app list first
  final appsAsync = ref.watch(appListProvider);
  final apps = appsAsync.asData?.value;

  if (apps != null) {
    final matches = apps.where((a) => a.packageName == packageName);
    if (matches.isNotEmpty && matches.first.iconBytes != null) {
      return matches.first.iconBytes;
    }
  }

  // Not cached — fetch from native
  final bytes =
      await PlatformChannelService.instance.getAppIcon(packageName);

  // Store in AppInfo for future lookups within same session
  if (apps != null && bytes != null) {
    final matches = apps.where((a) => a.packageName == packageName);
    if (matches.isNotEmpty) {
      matches.first.iconBytes = bytes;
    }
  }

  return bytes;
});

// ─────────────────────────────────────────────────────────────
// HOME SCREEN APPS — apps pinned to home screen
// Uses modern Riverpod 3.x Notifier style
// ─────────────────────────────────────────────────────────────
final homeScreenAppsProvider =
    NotifierProvider<HomeScreenAppsNotifier, List<String>>(
        HomeScreenAppsNotifier.new);

class HomeScreenAppsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addApp(String packageName) {
    if (!state.contains(packageName)) {
      state = [...state, packageName];
    }
  }

  void removeApp(String packageName) {
    state = state.where((p) => p != packageName).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  bool contains(String packageName) => state.contains(packageName);
}

// ─────────────────────────────────────────────────────────────
// DOCK APPS — apps pinned to the bottom dock bar
// Uses modern Riverpod 3.x Notifier style
// ─────────────────────────────────────────────────────────────
final dockAppsProvider =
    NotifierProvider<DockAppsNotifier, List<String>>(
        DockAppsNotifier.new);

class DockAppsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [
        'com.android.chrome',
        'com.google.android.gm',
        'com.google.android.apps.photos',
        'com.android.settings',
      ];

  bool addApp(String packageName) {
    if (state.length >= 4) return false;
    if (!state.contains(packageName)) {
      state = [...state, packageName];
      return true;
    }
    return false;
  }

  void removeApp(String packageName) {
    state = state.where((p) => p != packageName).toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  bool contains(String packageName) => state.contains(packageName);
}