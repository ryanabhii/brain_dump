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
        // Adaptive: on phones the app fills the screen; on tablets/desktop/web
        // it's centred at a comfortable phone width instead of stretching wide.
        builder: (context, child) => ColoredBox(
          color: Colors.black,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
        home: const RootShell(),
      ),
    );
  }
}

/// The app shell: a keep-alive crossfade between screens + bottom navigation.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0; // start on Home

  void _go(int i) => setState(() => _index = i);

  Widget _screenFor(int i) => switch (i) {
    0 => DashboardScreen(onNavigate: _go),
    1 => const KillzoneScreen(),
    2 => const SpendScreen(),
    3 => const CaptureScreen(),
    4 => const GroceryScreen(),
    5 => const BodyScreen(),
    _ => const ProfileScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (app.isLoading) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Loading tracker…',
            style: TextStyle(color: AppColors.zinc500),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // All seven screens stay mounted (state preserved); only the active one
        // is visible + interactive. Switching crossfades between them.
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < 7; i++)
              _TabLayer(active: i == _index, child: _screenFor(i)),
          ],
        ),
      ),
      bottomNavigationBar: TrackerBottomNav(currentIndex: _index, onTap: _go),
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
