import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_list_provider.dart';
import '../../widgets/app_icon/app_icon_widget.dart';
import '../../core/services/platform_channel_service.dart';
import 'app_drawer.dart';


/// The main launcher home screen.
/// This is what the user sees when they press the home button.
/// Phase 1: clean dark background, clock, icon grid, dock, drawer button.
/// Phase 2+: templates will replace the visual layer here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Watch app lifecycle — refresh app list if user installs/uninstalls
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from another app, refresh app list
    // in case user installed or uninstalled something
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(appListProvider);
    }
  }

  // Open app drawer as a full screen route
  void _openDrawer() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const AppDrawer(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Block Android back button — launchers should not go "back"
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ── Background ─────────────────────────────────────
            const _HomeBackground(),

            // ── Main content ───────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Clock + date section
                  const _ClockSection(),

                  const SizedBox(height: 24),

                  // Home screen app icons grid
                  const Expanded(child: _HomeIconGrid()),

                  // Dock at bottom
                  _Dock(onDrawerOpen: _openDrawer),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Swipe up anywhere on screen to open drawer ──────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! < -300) {
                    _openDrawer();
                  }
                },
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BACKGROUND
// Simple dark gradient for Phase 1
// Templates will completely replace this in Phase 2
// ─────────────────────────────────────────────────────────────
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D1A), Color(0xFF0A0A0A), Color(0xFF0D1A0D)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CLOCK SECTION
// Digital clock + date display
// Will become a widget system in Phase 3
// ─────────────────────────────────────────────────────────────
class _ClockSection extends StatefulWidget {
  const _ClockSection();

  @override
  State<_ClockSection> createState() => _ClockSectionState();
}

class _ClockSectionState extends State<_ClockSection> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startClock();
  }

  void _startClock() {
    Future.delayed(Duration(seconds: 60 - DateTime.now().second), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      // Then update every 60 seconds
      _tickEveryMinute();
    });
  }

  void _tickEveryMinute() {
    Future.delayed(const Duration(minutes: 1), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _tickEveryMinute();
    });
  }

  String get _timeString {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _amPm => _now.hour >= 12 ? 'PM' : 'AM';

  String get _dateString {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${days[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeString,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 6),
                child: Text(
                  _amPm,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Date
          Text(
            _dateString,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HOME ICON GRID
// Shows apps pinned to home screen
// ─────────────────────────────────────────────────────────────
class _HomeIconGrid extends ConsumerWidget {
  const _HomeIconGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedPackages = ref.watch(homeScreenAppsProvider);
    final appsAsync = ref.watch(appListProvider);

    return appsAsync.when(
      data: (allApps) {
        // Find AppInfo for each pinned package name
        final pinnedApps = pinnedPackages
            .map((pkg) {
              try {
                return allApps.firstWhere((a) => a.packageName == pkg);
              } catch (_) {
                return null;
              }
            })
            .whereType<dynamic>()
            .where((a) => a != null)
            .toList();

        if (pinnedApps.isEmpty) {
          return const _EmptyHomeHint();
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: pinnedApps.length,
          itemBuilder: (context, index) {
            final app = pinnedApps[index];
            return AppIconWidget(
              app: app,
              iconSize: 56,
              onTap: () =>
                  PlatformChannelService.instance.launchApp(app.packageName),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 2,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY HOME HINT
// Shown when no apps are pinned to home screen
// ─────────────────────────────────────────────────────────────
class _EmptyHomeHint extends StatelessWidget {
  const _EmptyHomeHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_up_outlined, color: AppColors.textHint, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Swipe up to see all apps',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Long press any app to add it here',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DOCK
// Bottom row of pinned apps + drawer button
// ─────────────────────────────────────────────────────────────
class _Dock extends ConsumerWidget {
  // Callback to open drawer passed from parent
  final VoidCallback onDrawerOpen;
  const _Dock({required this.onDrawerOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dockPackages = ref.watch(dockAppsProvider);
    final appsAsync = ref.watch(appListProvider);

    // Show pinned dock apps — only ones that exist on device
    final dockApps = dockPackages
        .map((pkg) {
          try {
            return appsAsync.asData?.value
                .firstWhere((a) => a.packageName == pkg);
          } catch (_) {
            return null;
          }
        })
        .whereType<dynamic>()
        .where((a) => a != null)
        .take(4)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dockBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.dockBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Dock app icons — only apps that actually exist on device
            ...dockApps.map(
              (app) => AppIconWidget(
                app: app,
                iconSize: 48,
                showLabel: false,
                isDockItem: true,
                onTap: () =>
                    PlatformChannelService.instance.launchApp(app.packageName),
              ),
            ),

            // Drawer button — always visible, always works
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDrawerOpen();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
