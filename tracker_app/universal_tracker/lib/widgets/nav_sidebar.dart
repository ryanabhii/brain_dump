import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import 'bottom_nav.dart';

/// Slide-in drawer that lists every nav destination, lets the user jump to
/// any one, and lets them pin/unpin the configurable middle tabs (1..5) so
/// they control what shows up in the bottom nav. Home (0) and Profile (6)
/// always appear there — the pin button is hidden for them.
class NavSidebar extends StatelessWidget {
  /// Active tab index — highlights the matching row.
  final int currentIndex;

  /// Switch to [index]. Called after the drawer is dismissed so the route
  /// transition feels snappy.
  final ValueChanged<int> onTap;

  const NavSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.data?.profile;
    final pinned =
        profile?.pinnedNavTabs.toSet() ?? kAllMiddleTabIndices.toSet();
    return Drawer(
      backgroundColor: AppColors.zinc950,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                'Navigate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.zinc100,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Tap to jump, pin to keep in the bottom bar',
                style: TextStyle(fontSize: 12, color: AppColors.zinc500),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                children: [
                  for (final tab in kNavTabs)
                    _NavRow(
                      tab: tab,
                      active: tab.index == currentIndex,
                      // Home + Profile are always rendered in the bottom nav,
                      // so they show a small "always shown" hint instead of
                      // a pin button.
                      pinnable: kAllMiddleTabIndices.contains(tab.index),
                      pinned: pinned.contains(tab.index),
                      onTap: () {
                        Navigator.of(context).pop();
                        onTap(tab.index);
                      },
                      onTogglePin: () => app.toggleNavPin(tab.index),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppColors.zinc600,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Unpinning hides a tab from the bottom bar; '
                      'reach it any time from this sidebar.',
                      style: TextStyle(fontSize: 11, color: AppColors.zinc600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final NavTabSpec tab;
  final bool active;
  final bool pinnable;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const _NavRow({
    required this.tab,
    required this.active,
    required this.pinnable,
    required this.pinned,
    required this.onTap,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.cyan300 : AppColors.zinc300;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.a(AppColors.cyan500, 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.a(AppColors.cyan500, 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.a(AppColors.cyan500, 0.18)
                    : AppColors.a(AppColors.zinc100, 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tab.icon, size: 18, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (pinnable)
              _PinButton(pinned: pinned, onTap: onTogglePin)
            else
              const _AlwaysPinnedBadge(),
          ],
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final bool pinned;
  final VoidCallback onTap;
  const _PinButton({required this.pinned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: pinned ? 'Unpin from bottom bar' : 'Pin to bottom bar',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: pinned
                ? AppColors.a(AppColors.cyan500, 0.15)
                : AppColors.a(AppColors.zinc100, 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: pinned
                  ? AppColors.a(AppColors.cyan500, 0.4)
                  : Colors.transparent,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            transitionBuilder: (c, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.85, end: 1.0).animate(anim),
              child: FadeTransition(opacity: anim, child: c),
            ),
            child: Icon(
              pinned ? Icons.push_pin : Icons.push_pin_outlined,
              key: ValueKey(pinned),
              size: 16,
              color: pinned ? AppColors.cyan300 : AppColors.zinc500,
            ),
          ),
        ),
      ),
    );
  }
}

class _AlwaysPinnedBadge extends StatelessWidget {
  const _AlwaysPinnedBadge();

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Always in the bottom bar',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.lock_outline, size: 14, color: AppColors.zinc600),
    ),
  );
}
