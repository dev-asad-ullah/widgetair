import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetair/providers/app_list_provider.dart';

void main() {
  test('homeScreenAppsProvider starts empty and does not affect dockAppsProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state
    expect(container.read(homeScreenAppsProvider), isEmpty);
    expect(container.read(dockAppsProvider), [
      'com.android.chrome',
      'com.google.android.gm',
      'com.google.android.apps.photos',
      'com.android.settings',
    ]);

    // Add app to Home Screen
    container.read(homeScreenAppsProvider.notifier).addApp('com.example.testapp');

    // Verify Home Screen has the app
    expect(container.read(homeScreenAppsProvider), ['com.example.testapp']);

    // Verify Dock does NOT contain the new app
    expect(container.read(dockAppsProvider), [
      'com.android.chrome',
      'com.google.android.gm',
      'com.google.android.apps.photos',
      'com.android.settings',
    ]);
  });

  test('dockAppsProvider operations are independent of homeScreenAppsProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Remove an app from Dock
    container.read(dockAppsProvider.notifier).removeApp('com.android.chrome');
    expect(container.read(dockAppsProvider), [
      'com.google.android.gm',
      'com.google.android.apps.photos',
      'com.android.settings',
    ]);

    // Add new app to Dock
    final added = container.read(dockAppsProvider.notifier).addApp('com.example.dockapp');
    expect(added, isTrue);
    expect(container.read(dockAppsProvider).contains('com.example.dockapp'), isTrue);

    // Home Screen is still empty
    expect(container.read(homeScreenAppsProvider), isEmpty);
  });
}
