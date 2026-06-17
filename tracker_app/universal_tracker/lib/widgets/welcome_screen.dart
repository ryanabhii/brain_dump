import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart' show PhoneWidth;
import '../theme/colors.dart';

/// One page in the walkthrough — either an intro/outro hero or a tab tour.
class WelcomePage {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;

  /// Short bullet rows shown under the hero. Each is "do this → see that".
  final List<String> bullets;

  /// Optional hint about which bottom-nav entry this maps to (e.g. "Pantry").
  /// Helps users link the description to the icon they'll tap next.
  final String? navHint;

  const WelcomePage({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.bullets = const [],
    this.navHint,
  });
}

/// The walkthrough deck. Order roughly follows the bottom-nav, with a hello
/// page first and a "you're ready" page last so the user always lands on a
/// gentle CTA. Edit copy here — it is the single source of truth.
const List<WelcomePage> kWelcomePages = [
  WelcomePage(
    icon: Icons.waving_hand_outlined,
    accent: AppColors.cyan300,
    title: 'Welcome to Tracker',
    subtitle:
        'A local-first, offline-friendly app for trading sessions, spend, '
        'capture, household, and body — all in one place.',
    bullets: [
      'Everything saves on-device first. No account needed.',
      'Sign in with Google later to back up + share tabs across devices.',
      'Pull down on any screen to sync now.',
    ],
  ),
  WelcomePage(
    icon: Icons.home_rounded,
    accent: AppColors.cyan400,
    title: 'Home',
    subtitle:
        'A live summary of every tab. Tap any card to jump straight to it.',
    bullets: [
      "See your next killzone, today's macros, and pending captures at a glance.",
      'Greeting, streak, and live "now" indicator update automatically.',
    ],
    navHint: 'Home',
  ),
  WelcomePage(
    icon: Icons.trending_up,
    accent: AppColors.amber400,
    title: 'Trading',
    subtitle:
        'Killzones (your trading session windows), live state, and a journal.',
    bullets: [
      'Add a killzone with start/end times and an alert lead.',
      "Toggle alert per-zone, or skip-today when you're flat.",
      'Log W/L journal entries to build a 7-day win-rate.',
    ],
    navHint: 'Trading',
  ),
  WelcomePage(
    icon: Icons.credit_card,
    accent: AppColors.rose400,
    title: 'Spend',
    subtitle: 'Subscriptions and API budgets in one feed.',
    bullets: [
      'Add a subscription with cost + renewal cadence.',
      'For API-type entries, log usage to see burn vs. cap.',
      'Tap the used switch each month to track what you actually used.',
    ],
    navHint: 'Spend',
  ),
  WelcomePage(
    icon: Icons.psychology_alt,
    accent: AppColors.violet400,
    title: 'Capture',
    subtitle:
        'A frictionless brain dump for ideas, reminders, and follow-ups.',
    bullets: [
      'Type anywhere — tag is auto-detected (or pick one).',
      'Tap the mic to record a voice note — transcribed on-device.',
      'Set a reminder to get a future nudge.',
      'Promote a dump to a grocery item or check it off when done.',
    ],
    navHint: 'Capture',
  ),
  WelcomePage(
    icon: Icons.shopping_cart,
    accent: AppColors.emerald400,
    title: 'Pantry & Groceries',
    subtitle:
        'Shopping list, pantry stock, and household members in one place.',
    bullets: [
      'Add items by name + qty. Tap to mark bought.',
      'Pantry tracks stock with a low-threshold — one tap moves it to the list.',
      'Multiple members? Cycle who an item is for with a tap.',
    ],
    navHint: 'Pantry',
  ),
  WelcomePage(
    icon: Icons.fitness_center,
    accent: AppColors.sky400,
    title: 'Body',
    subtitle: 'Meals, macros, workouts, water, and streaks.',
    bullets: [
      "Log a meal with kcal/protein/carbs/fat — macros roll into today's totals.",
      'Add workouts with focus + duration to feed the "This week" list.',
      'Tap water to add a glass; freeze a streak with a streak freeze.',
    ],
    navHint: 'Body',
  ),
  WelcomePage(
    icon: Icons.person,
    accent: AppColors.zinc300,
    title: 'Profile',
    subtitle: 'Notifications, household, sync, and data tools.',
    bullets: [
      'Set quiet hours, lead-time, and the daily-review nudge.',
      'Tap "Request all permissions" to enable notifications + Drive sync.',
      'Copy a JSON backup of everything any time you want.',
    ],
    navHint: 'Profile',
  ),
  WelcomePage(
    icon: Icons.rocket_launch_outlined,
    accent: AppColors.cyan300,
    title: "You're set",
    subtitle:
        'Tap "Get started" to begin. You can replay this walkthrough any '
        'time from Profile → Help.',
  ),
];

/// Full-screen walkthrough shown on first launch (after data loads, before
/// the permissions dialog). Also reachable from Profile → Help → "Show
/// welcome" so users can revisit it without resetting their data.
class WelcomeScreen extends StatefulWidget {
  /// Called once the user finishes or skips. The caller persists the
  /// "welcome seen" flag.
  final VoidCallback onDone;
  const WelcomeScreen({super.key, required this.onDone});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDone,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => WelcomeScreen(onDone: onDone),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final _controller = PageController();

  /// Continuous page position (1.5 mid-swipe between page 1 and 2). Drives
  /// the parallax + background-tint crossfade so the whole screen breathes
  /// with the swipe instead of snapping.
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!_controller.hasClients) return;
      final p = _controller.page ?? 0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _index => _page.round();
  bool get _isLast => _index == kWelcomePages.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _prev() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    widget.onDone();
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Blend two pages' accents by the fractional swipe position so the
  /// ambient glow tweens smoothly mid-drag.
  Color get _blendedAccent {
    final lo = _page.floor().clamp(0, kWelcomePages.length - 1);
    final hi = _page.ceil().clamp(0, kWelcomePages.length - 1);
    final t = _page - lo;
    return Color.lerp(
          kWelcomePages[lo].accent,
          kWelcomePages[hi].accent,
          t,
        ) ??
        kWelcomePages[lo].accent;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.zinc950,
      ),
      child: PhoneWidth(
        child: Scaffold(
          backgroundColor: AppColors.zinc950,
          body: Stack(
          children: [
            // Ambient gradient that tints with the current page's accent.
            Positioned.fill(child: _AmbientBackdrop(accent: _blendedAccent)),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    index: _index,
                    total: kWelcomePages.length,
                    onSkip: _finish,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: kWelcomePages.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (_, i) => _WelcomePageView(
                        page: kWelcomePages[i],
                        pageIndex: i,
                        scrollPosition: _page,
                      ),
                    ),
                  ),
                  _DotsIndicator(
                    count: kWelcomePages.length,
                    position: _page,
                    color: _blendedAccent,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      children: [
                        _GhostButton(
                          label: 'Back',
                          onTap: _index == 0 ? null : _prev,
                        ),
                        const Spacer(),
                        _PrimaryButton(
                          label: _isLast ? 'Get started' : 'Next',
                          accent: _blendedAccent,
                          onTap: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Background ────────────────────────────────────────────────────────────

/// Two radial glows (one top-left, one bottom-right) tinted with the current
/// page accent — gives every page a calm, distinct mood without distracting
/// from the content. Animates its color with the swipe via the rebuild loop.
class _AmbientBackdrop extends StatelessWidget {
  final Color accent;
  const _AmbientBackdrop({required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.85),
          radius: 1.2,
          colors: [
            AppColors.a(accent, 0.16),
            AppColors.a(accent, 0.05),
            AppColors.zinc950,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.95, 1.1),
            radius: 1.1,
            colors: [
              AppColors.a(accent, 0.10),
              AppColors.a(accent, 0.0),
            ],
            stops: const [0.0, 0.8],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar (counter + skip) ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onSkip;
  const _TopBar({
    required this.index,
    required this.total,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          // "3 / 9" — quiet counter so users always know how much is left.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.a(AppColors.zinc100, 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.a(AppColors.zinc100, 0.06)),
            ),
            child: Text(
              '${index + 1}  /  $total',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.zinc400,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: AppColors.zinc400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page body ────────────────────────────────────────────────────────────

class _WelcomePageView extends StatelessWidget {
  final WelcomePage page;
  final int pageIndex;
  final double scrollPosition;
  const _WelcomePageView({
    required this.page,
    required this.pageIndex,
    required this.scrollPosition,
  });

  @override
  Widget build(BuildContext context) {
    // Distance from this page to the viewport center, in pages. 0 = focused,
    // ±1 = fully off-screen. Used to drive subtle parallax so the hero
    // doesn't feel "stuck" to the page edges as you swipe.
    final delta = (pageIndex - scrollPosition).clamp(-1.0, 1.0);
    final absDelta = delta.abs();
    // Focused page fades fully in; neighbors are dim until you swipe.
    final opacity = (1.0 - absDelta).clamp(0.0, 1.0);
    // Slight horizontal slide + scale gives the hero a counter-parallax feel.
    final dx = delta * 40; // px
    final scale = 1 - (absDelta * 0.04);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Opacity(
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: scale,
                child: _HeroIcon(icon: page.icon, accent: page.accent),
              ),
            ),
            const SizedBox(height: 28),
            if (page.navHint != null) ...[
              _NavChip(label: page.navHint!, accent: page.accent),
              const SizedBox(height: 12),
            ],
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                height: 1.1,
                color: AppColors.zinc100,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: AppColors.zinc400,
                letterSpacing: 0.1,
              ),
            ),
            if (page.bullets.isNotEmpty) ...[
              const SizedBox(height: 28),
              for (final b in page.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BulletCard(text: b, accent: page.accent),
                ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Hero icon ────────────────────────────────────────────────────────────

/// Big rounded-square icon with a soft accent glow halo behind it.
class _HeroIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  const _HeroIcon({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Subtle vertical gradient + accent ring so the icon reads as a
        // tactile chip, not a flat square.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.a(accent, 0.22),
            AppColors.a(accent, 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.a(accent, 0.35), width: 1.2),
        boxShadow: [
          // Outer glow — gives every page a unique ambient color.
          BoxShadow(
            color: AppColors.a(accent, 0.28),
            blurRadius: 36,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.a(accent, 0.10),
            blurRadius: 80,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(icon, size: 50, color: accent),
    );
  }
}

// ─── Nav chip ─────────────────────────────────────────────────────────────

class _NavChip extends StatelessWidget {
  final String label;
  final Color accent;
  const _NavChip({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.a(accent, 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.a(accent, 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_up_alt, size: 12, color: accent),
          const SizedBox(width: 6),
          Text(
            'Bottom nav  ·  $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bullet card ──────────────────────────────────────────────────────────

class _BulletCard extends StatelessWidget {
  final String text;
  final Color accent;
  const _BulletCard({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.a(AppColors.zinc100, 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.a(AppColors.zinc100, 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small glowing accent dot — keeps the rhythm visual without a
          // heavy icon eating horizontal space.
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.a(accent, 0.6), blurRadius: 8),
              ],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.zinc300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dots indicator ───────────────────────────────────────────────────────

/// A row of dots where the focused one stretches into an accent pill. The
/// stretch tracks the continuous swipe position so it slides between dots
/// as you drag, instead of snapping at the page boundary.
class _DotsIndicator extends StatelessWidget {
  final int count;
  final double position;
  final Color color;
  const _DotsIndicator({
    required this.count,
    required this.position,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _Dot(
                activeness: 1 - (position - i).abs().clamp(0, 1).toDouble(),
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double activeness; // 0 = inactive, 1 = focused
  final Color color;
  const _Dot({required this.activeness, required this.color});

  @override
  Widget build(BuildContext context) {
    // Smooth interpolation so the highlighted dot stretches as you swipe.
    final t = Curves.easeOut.transform(activeness);
    final width = 6 + 16 * t;
    final glow = AppColors.a(color, 0.4 * t);
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.zinc700, color, t),
        borderRadius: BorderRadius.circular(3),
        boxShadow: t > 0.05
            ? [BoxShadow(color: glow, blurRadius: 8 * t)]
            : null,
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? AppColors.zinc300 : AppColors.zinc700,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pull the foreground toward dark when the accent is light, and toward
    // light when the accent is dark, so the label always has WCAG-passing
    // contrast against the pill background.
    final isLight =
        accent.computeLuminance() > 0.55; // pale cyan/zinc → dark text
    final fg = isLight ? AppColors.zinc950 : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, AppColors.a(accent, 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.a(accent, 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.a(Colors.white, 0.08),
          highlightColor: AppColors.a(Colors.white, 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
