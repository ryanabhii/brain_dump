import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/body_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/grocery_screen.dart';
import 'screens/killzone_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/spend_screen.dart';
import 'services/notifications.dart';
import 'services/storage_service.dart';
import 'services/time_zone.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/nav_sidebar.dart';
import 'widgets/permissions_dialog.dart';
import 'widgets/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final timezoneName = await initTimeZone();
  await Notifications.init(); // no-op on web
  runApp(TrackerApp(timezoneName: timezoneName));
}

class TrackerApp extends StatelessWidget {
  final String timezoneName;
  const TrackerApp({super.key, this.timezoneName = 'UTC'});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(StorageService(), localTimezone: timezoneName),
      child: MaterialApp(
        title: 'Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // NOTE: we deliberately do NOT clamp width here via `builder:` —
        // `MaterialApp.builder` wraps the Navigator, so any constraint
        // applied here would also constrain dialogs (showDatePicker, popup
        // menus) and cause them to flicker as their AnimatedSize widgets
        // fight the clamp. The phone-width visual is applied per-route
        // instead (see [RootShell] + [PhoneWidth] below) so dialogs stay
        // happily full-screen.
        home: const RootShell(),
      ),
    );
  }
}

/// Centers its [child] at a comfortable phone width on tablets / desktop /
/// web, with black gutters either side. Phones (≤448 logical px wide) see
/// the child fill the screen, identical to before. Apply at the top of each
/// screen / fullscreen-dialog route's `build`.
class PhoneWidth extends StatelessWidget {
  final Widget child;
  const PhoneWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: child,
      ),
    ),
  );
}

/// The app shell: a keep-alive crossfade between screens + bottom navigation.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0; // start on Home
  late final List<Widget> _screens;
  bool _onboardingStarted = false;

  /// Scaffold key so widgets that aren't descendants of the Scaffold (e.g.
  /// the bottomNavigationBar's empty-state opener) can still open the drawer
  /// without needing a Builder hop.
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Build each screen exactly once. _TabLayer keeps all of them mounted;
    // recreating them on every build broke InheritedWidget subscriptions and
    // caused '_dependents.isEmpty' / 'dirty widget in wrong scope' errors.
    _screens = [
      DashboardScreen(onNavigate: _go),
      const KillzoneScreen(),
      const SpendScreen(),
      const CaptureScreen(),
      const GroceryScreen(),
      const BodyScreen(),
      const ProfileScreen(),
    ];
  }

  /// First-launch onboarding: walkthrough first (so the user knows what each
  /// permission unlocks), then the permissions dialog. Each step has its own
  /// persisted "seen" flag so re-running one doesn't trigger the other.
  void _maybeRunOnboarding(AppState app) {
    if (_onboardingStarted || app.isLoading) return;
    _onboardingStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        // Storage was unreadable at startup: the app recovered by loading
        // defaults, keeping the original bytes quarantined. Never silently —
        // the user must know their history isn't gone, just unreadable.
        if (app.dataRecoveredFromCorruption) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Data recovered'),
              content: const Text(
                'Your saved data could not be read, so the app started with '
                'defaults. The unreadable copy has been kept — nothing was '
                'deleted. Restoring from your Drive backup (Profile → Data) '
                'will bring your history back.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        if (!mounted) return;
        final seenWelcome = await app.hasSeenWelcome();
        if (!seenWelcome) {
          if (!mounted) return;
          await WelcomeScreen.show(
            context,
            onDone: () => app.markWelcomeSeen(),
          );
        }
        if (!mounted) return;
        if (await app.hasOnboardedPermissions()) return;
        if (!mounted) return;
        await PermissionsDialog.show(context, firstLaunch: true);
        await app.markPermissionsOnboarded();
      } catch (e, st) {
        // Log but don't crash: onboarding is optional. In release mode an
        // unguarded throw here would silently swallow the error and leave
        // the user without the welcome screen AND permissions dialog.
        debugPrint('Onboarding error: $e\n$st');
        // Still try to show the permissions dialog even if welcome failed.
        if (!mounted) return;
        try {
          if (!await app.hasOnboardedPermissions()) {
            if (!mounted) return;
            await PermissionsDialog.show(context, firstLaunch: true);
            await app.markPermissionsOnboarded();
          }
        } catch (e2) {
          debugPrint('Permissions dialog error: $e2');
        }
      }
    });
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.isLoading) {
      return const PhoneWidth(
        child: Scaffold(
          body: Center(
            child: Text(
              'Loading tracker…',
              style: TextStyle(color: AppColors.zinc500),
            ),
          ),
        ),
      );
    }

    // First-launch only — schedules the dialog for after this frame.
    _maybeRunOnboarding(app);

    return PhoneWidth(
      child: Scaffold(
        key: _scaffoldKey,
        // Sidebar with every nav destination + per-tab pin toggle. Wired at
        // the shell level so swipe-from-left works on every screen, and so
        // tapping a row can hop tabs without an extra pop.
        drawer: NavSidebar(currentIndex: _index, onTap: _go),
        body: SafeArea(
          bottom: false,
          // All seven screens stay mounted (state preserved); only the active
          // one is visible + interactive. Switching crossfades between them.
          // Wrapped in a RefreshIndicator so pulling down on any tab's
          // scrollable triggers a manual sync. Inactive tabs are
          // IgnorePointer'd so only the active scrollable forwards overscroll
          // notifications.
          child: RefreshIndicator(
            onRefresh: () => _manualSync(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < 7; i++)
                  _TabLayer(active: i == _index, child: _screens[i]),
              ],
            ),
          ),
        ),
        bottomNavigationBar: TrackerBottomNav(
          currentIndex: _index,
          onTap: _go,
          onOpenSidebar: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }

  /// Pull-to-refresh handler: run a sync pass and surface the result. Safe to
  /// call when signed out (returns "Sign in to sync") or already syncing
  /// ("Sync in progress…") \u2014 [AppState.syncNow] handles both.
  Future<void> _manualSync(BuildContext context) async {
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final msg = await app.syncNow();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

/// Keeps its [child] mounted (so its state survives) while fading it in/out and
/// disabling pointers + tickers when it isn't the active tab.
class _TabLayer extends StatelessWidget {
  final bool active;
  final Widget child;
  const _TabLayer({required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: const Duration(milliseconds: 220),
      curve: active ? Curves.easeOut : Curves.easeIn,
      child: IgnorePointer(
        ignoring: !active,
        child: TickerMode(enabled: active, child: child),
      ),
    );
  }
}
