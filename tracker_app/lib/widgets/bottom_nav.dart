import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Bottom navigation matching the prototype's design: **Home pinned left**,
/// **Profile pinned right**, and the five middle tabs in a horizontally
/// scrollable strip with fade-out edges + chevron hints, so it's clear there's
/// more to scroll. The active middle tab auto-scrolls into view.
class TrackerBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const TrackerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<TrackerBottomNav> createState() => _TrackerBottomNavState();
}

class _TrackerBottomNavState extends State<TrackerBottomNav> {
  // Index order matches RootShell's screen list.
  static const _tabs = <({IconData icon, String label})>[
    (icon: Icons.home_rounded, label: 'Home'), // 0 — fixed left
    (icon: Icons.trending_up, label: 'Trading'), // 1
    (icon: Icons.credit_card, label: 'Spend'), // 2
    (icon: Icons.psychology_alt, label: 'Capture'), // 3
    (icon: Icons.shopping_cart, label: 'Pantry'), // 4
    (icon: Icons.fitness_center, label: 'Body'), // 5
    (icon: Icons.person, label: 'Profile'), // 6 — fixed right
  ];
  static const _middle = [1, 2, 3, 4, 5];

  final _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {for (final i in _middle) i: GlobalKey()};
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
    final right = p.pixels < p.maxScrollExtent - 1;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _ensureActiveVisible() {
    if (!_middle.contains(widget.currentIndex)) return;
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

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _middleStrip()),
              _cell(6, width: 66),
            ],
          ),
        ),
      ),
    );
  }

  Widget _middleStrip() {
    return LayoutBuilder(
      builder: (context, _) {
        // Re-evaluate arrow visibility once this strip has been laid out.
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
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
                    for (final i in _middle)
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
    final t = _tabs[index];
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
