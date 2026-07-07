import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';

/// Single source of truth for every nav destination. Indices match the order
/// in `RootShell._screens`, so a tab's index *is* its on-screen position.
/// Used by both the bottom nav and the sidebar so renaming or reordering
/// here ripples everywhere.
class NavTabSpec {
  final int index;
  final IconData icon;
  final String label;
  const NavTabSpec({
    required this.index,
    required this.icon,
    required this.label,
  });
}

const List<NavTabSpec> kNavTabs = [
  NavTabSpec(index: 0, icon: Icons.home_rounded, label: 'Home'),
  NavTabSpec(index: 1, icon: Icons.trending_up, label: 'Trading'),
  NavTabSpec(index: 2, icon: Icons.credit_card, label: 'Spend'),
  NavTabSpec(index: 3, icon: Icons.psychology_alt, label: 'Capture'),
  NavTabSpec(index: 4, icon: Icons.shopping_cart, label: 'Pantry'),
  NavTabSpec(index: 5, icon: Icons.fitness_center, label: 'Body'),
  NavTabSpec(index: 6, icon: Icons.person, label: 'Profile'),
];

/// Middle (user-pinnable) tabs — Home and Profile are always rendered, so
/// the only configurable indices are 1..5.
const List<int> kAllMiddleTabIndices = [1, 2, 3, 4, 5];

/// Bottom navigation matching the prototype's design: **Home pinned left**,
/// **Profile pinned right**, and the user-selected middle tabs in a
/// horizontally scrollable strip with fade-out edges + chevron hints, so it's
/// clear there's more to scroll. The active middle tab auto-scrolls into view.
class TrackerBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Called when the user taps the empty-state hint to open the sidebar.
  /// Without this, unpinning every middle tab would soft-lock the only
  /// entry point to the sidebar (the dashboard's hamburger) to one screen.
  final VoidCallback? onOpenSidebar;

  const TrackerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onOpenSidebar,
  });

  @override
  State<TrackerBottomNav> createState() => _TrackerBottomNavState();
}

class _TrackerBottomNavState extends State<TrackerBottomNav> {
  final _scroll = ScrollController();
  Map<int, GlobalKey> _keys = {};
  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
      _ensureActiveVisible();
    });
  }

  @override
  void didUpdateWidget(covariant TrackerBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureActiveVisible(),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final left = p.pixels > 1;
    // hasContentDimensions==false right after a rebuild that shrinks the
    // content; treat that as no right arrow to avoid a single-frame ghost.
    final right = p.hasContentDimensions && p.pixels < p.maxScrollExtent - 1;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _ensureActiveVisible() {
    final ctx = _keys[widget.currentIndex]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Pinned middle indices ordered canonically (kAllMiddleTabIndices order).
  /// Pulled from AppState; falls back to all five when state is loading.
  List<int> _pinnedMiddle(BuildContext context) {
    final p = context.watch<AppState>().data?.profile;
    final pinned = p?.pinnedNavTabs.toSet() ?? kAllMiddleTabIndices.toSet();
    return [
      for (final i in kAllMiddleTabIndices)
        if (pinned.contains(i)) i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final middle = _pinnedMiddle(context);
    // Rebuild the GlobalKey map so each pinned tab keeps a stable key across
    // rebuilds for the auto-scroll-into-view to keep working.
    _keys = {for (final i in middle) i: _keys[i] ?? GlobalKey()};
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.zinc950,
        border: Border(top: BorderSide(color: AppColors.zinc800)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _cell(0, width: 66),
              Expanded(child: _middleStrip(middle)),
              _cell(6, width: 66),
            ],
          ),
        ),
      ),
    );
  }

  Widget _middleStrip(List<int> middle) {
    return LayoutBuilder(
      builder: (context, _) {
        // Re-evaluate arrow visibility once this strip has been laid out.
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
        if (middle.isEmpty) {
          // Empty state: tappable opener so a user who unpinned everything
          // can still reach the sidebar from any screen, not just the
          // dashboard.
          return Center(
            child: InkWell(
              onTap: widget.onOpenSidebar,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_open_rounded,
                      size: 14,
                      color: AppColors.cyan400,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Pin tabs from the sidebar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final l = _canLeft ? 0.08 : 0.0;
        final r = _canRight ? 0.92 : 1.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, l, r, 1.0],
              ).createShader(rect),
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final i in middle)
                      KeyedSubtree(key: _keys[i], child: _cell(i, width: 76)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _canLeft ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: AppColors.cyan400,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _canRight ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.cyan400,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _cell(int index, {required double width}) {
    final t = kNavTabs[index];
    final active = widget.currentIndex == index;
    return GestureDetector(
      key: ValueKey('navTab$index'),
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(index),
      child: SizedBox(
        width: width,
        // Tween the colour so the active state fades in/out smoothly.
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 220),
          tween: ColorTween(
            end: active ? AppColors.cyan400 : AppColors.zinc500,
          ),
          builder: (_, color, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Icon(t.icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                t.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
