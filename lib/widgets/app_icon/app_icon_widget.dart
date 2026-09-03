import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_info.dart';
import '../../providers/app_list_provider.dart';
import '../../core/services/platform_channel_service.dart';
import '../../core/theme/colors.dart';

/// Renders a single app icon with label.
/// Handles its own icon loading state — shows shimmer while loading,
/// fallback icon if load fails, actual icon when ready.
class AppIconWidget extends ConsumerStatefulWidget {
  final AppInfo app;
  final double iconSize;
  final double fontSize;
  final bool showLabel;
  final bool isDockItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppIconWidget({
    super.key,
    required this.app,
    this.iconSize = 56,
    this.fontSize = 11,
    this.showLabel = true,
    this.isDockItem = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  ConsumerState<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends ConsumerState<AppIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // LONG PRESS CONTEXT MENU
  // ─────────────────────────────────────────────────────────────
  void _showContextMenu(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final isPinnedHome = ref
        .read(homeScreenAppsProvider.notifier)
        .contains(widget.app.packageName);
    final isPinnedDock = ref
        .read(dockAppsProvider.notifier)
        .contains(widget.app.packageName);

    showMenu(
      context: context,
      color: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + box.size.width,
        position.dy + box.size.height,
      ),
      items: [
        if (widget.isDockItem) ...[
          PopupMenuItem(
            onTap: () => ref
                .read(dockAppsProvider.notifier)
                .removeApp(widget.app.packageName),
            child: const _ContextMenuItem(
              icon: Icons.remove_circle_outline,
              label: 'Remove from Dock',
            ),
          ),
        ] else ...[
          // Add OR Remove from Home
          if (isPinnedHome)
            PopupMenuItem(
              onTap: () => ref
                  .read(homeScreenAppsProvider.notifier)
                  .removeApp(widget.app.packageName),
              child: const _ContextMenuItem(
                icon: Icons.remove_circle_outline,
                label: 'Remove from Home',
              ),
            )
          else
            PopupMenuItem(
              onTap: () => ref
                  .read(homeScreenAppsProvider.notifier)
                  .addApp(widget.app.packageName),
              child: const _ContextMenuItem(
                icon: Icons.add_circle_outline,
                label: 'Add to Home',
              ),
            ),

          // Add OR Remove from Dock
          if (isPinnedDock)
            PopupMenuItem(
              onTap: () => ref
                  .read(dockAppsProvider.notifier)
                  .removeApp(widget.app.packageName),
              child: const _ContextMenuItem(
                icon: Icons.remove_circle_outline,
                label: 'Remove from Dock',
              ),
            )
          else
            PopupMenuItem(
              onTap: () {
                final added = ref
                    .read(dockAppsProvider.notifier)
                    .addApp(widget.app.packageName);
                if (!added && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dock is full (maximum 4 apps)'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const _ContextMenuItem(
                icon: Icons.dock_rounded,
                label: 'Add to Dock',
              ),
            ),
        ],

        PopupMenuItem(
          onTap: () => PlatformChannelService.instance.openAppSettings(
            widget.app.packageName,
          ),
          child: const _ContextMenuItem(
            icon: Icons.info_outline,
            label: 'App Info',
          ),
        ),

        PopupMenuItem(
          onTap: () => PlatformChannelService.instance.uninstallApp(
            widget.app.packageName,
          ),
          child: const _ContextMenuItem(
            icon: Icons.delete_outline,
            label: 'Uninstall',
            isDestructive: true,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconAsync = ref.watch(appIconProvider(widget.app.packageName));

    return GestureDetector(
      onTap: () async {
        await _pressController.forward();
        await _pressController.reverse();
        widget.onTap?.call();
      },
      onLongPress: () {
        widget.onLongPress?.call();
        _showContextMenu(context);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.iconSize + 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon container ──────────────────────────────
              SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: iconAsync.when(
                  data: (bytes) {
                    if (bytes == null)
                      return _FallbackIcon(size: widget.iconSize);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                        widget.iconSize * 0.22,
                      ),
                      child: Image.memory(
                        bytes,
                        width: widget.iconSize,
                        height: widget.iconSize,
                        fit: BoxFit.cover,
                        // Disable gapless playback to reduce rebuilds
                        gaplessPlayback: true,
                      ),
                    );
                  },
                  loading: () => _ShimmerIcon(size: widget.iconSize),
                  error: (_, __) => _FallbackIcon(size: widget.iconSize),
                ),
              ),

              // ── App name label ──────────────────────────────
              if (widget.showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  widget.app.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w400,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHIMMER LOADING PLACEHOLDER
// ─────────────────────────────────────────────────────────────
class _ShimmerIcon extends StatefulWidget {
  final double size;
  const _ShimmerIcon({required this.size});

  @override
  State<_ShimmerIcon> createState() => _ShimmerIconState();
}

class _ShimmerIconState extends State<_ShimmerIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_animation.value * 0.15),
          borderRadius: BorderRadius.circular(widget.size * 0.22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FALLBACK ICON — shown when icon fails to load
// ─────────────────────────────────────────────────────────────
class _FallbackIcon extends StatelessWidget {
  final double size;
  const _FallbackIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(Icons.apps, color: AppColors.textSecondary, size: size * 0.5),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTEXT MENU ITEM
// ─────────────────────────────────────────────────────────────
class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}
