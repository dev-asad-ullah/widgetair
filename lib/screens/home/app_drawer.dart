import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../providers/app_list_provider.dart';
import '../../widgets/app_icon/app_icon_widget.dart';
import '../../core/services/platform_channel_service.dart';

/// Full screen app drawer — slides up from bottom.
/// Shows all installed apps in a scrollable grid with search.
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Play entrance animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Close drawer with exit animation
  Future<void> _close() async {
    _searchFocus.unfocus();
    await _animController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = ref.watch(filteredAppListProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _close,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: AppColors.drawerBg,
            child: GestureDetector(
              // Prevent taps inside drawer from closing it
              onTap: () {},
              child: SlideTransition(
                position: _slideAnimation,
                child: SizedBox(
                  height: screenHeight,
                  child: Column(
                    children: [
                      // ── Top handle + close area ───────────────
                      GestureDetector(
                        onTap: _close,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 12,
                            bottom: 12,
                          ),
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.textHint,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Search bar ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _SearchBar(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (query) {
                            ref
                                .read(searchQueryProvider.notifier)
                                .setQuery(query);
                          },
                          onClear: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).clear();
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── App grid ──────────────────────────────
                      Expanded(
                        child: filteredApps.when(
                          data: (apps) {
                            if (apps.isEmpty) {
                              return _EmptyState(
                                query: ref.watch(searchQueryProvider),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.78,
                                  ),
                              itemCount: apps.length,
                              // cacheExtent improves scroll performance
                              cacheExtent: 500,
                              itemBuilder: (context, index) {
                                final app = apps[index];
                                return AppIconWidget(
                                  app: app,
                                  iconSize: 54,
                                  fontSize: 11,
                                  onTap: () {
                                    PlatformChannelService.instance.launchApp(
                                      app.packageName,
                                    );
                                    _close();
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const _LoadingGrid(),
                          error: (err, _) => _ErrorState(error: err.toString()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.searchBarBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.searchBarBorder),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textHint,
            size: 20,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textHint,
                  size: 18,
                ),
                onPressed: onClear,
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        textInputAction: TextInputAction.search,
        cursorColor: AppColors.accent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LOADING STATE — skeleton grid while apps load
// ─────────────────────────────────────────────────────────────
class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: 20,
      itemBuilder: (context, index) => const _SkeletonIcon(),
    );
  }
}

class _SkeletonIcon extends StatelessWidget {
  const _SkeletonIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE — no search results
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: AppColors.textHint, size: 48),
          const SizedBox(height: 12),
          Text(
            'No apps found for "$query"',
            style: const TextStyle(color: AppColors.textHint, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Could not load apps',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
