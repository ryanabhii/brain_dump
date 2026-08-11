import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/drive_web_button.dart';
import '../services/permissions.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/ui.dart';

/// Modal that explains every permission the app needs and requests them in
/// one batch. Shown automatically on first launch (see RootShell), and also
/// reachable from the Profile screen via "Request all permissions".
class PermissionsDialog extends StatefulWidget {
  /// When true, the dialog was triggered on first launch — the dismiss action
  /// is labelled "Skip" instead of "Close". Cosmetic only.
  final bool firstLaunch;
  const PermissionsDialog({super.key, this.firstLaunch = false});

  /// Convenience: open the dialog. Returns when it is dismissed.
  static Future<void> show(BuildContext context, {bool firstLaunch = false}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !firstLaunch,
      builder: (_) => PermissionsDialog(firstLaunch: firstLaunch),
    );
  }

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  late final PermissionsService _service;
  Map<AppPermission, PermissionOutcome> _state = const {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = PermissionsService(context.read<AppState>());
    _state = _service.snapshot();
  }

  Future<void> _grantAll() async {
    setState(() => _busy = true);
    try {
      final results = await _service.requestAll();
      if (!mounted) return;
      setState(() => _state = {..._state, ...results});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grantOne(AppPermission p) async {
    setState(() => _busy = true);
    try {
      final r = await _service.request(p);
      if (!mounted) return;
      setState(() => _state[p] = r);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch AppState so the Drive row re-renders the moment web sign-in
    // completes via the GIS button (DriveSyncService calls notifyListeners
    // when the user changes). For non-watched fields the snapshot is cheap.
    final app = context.watch<AppState>();
    // Live-refresh the Drive row's outcome from AppState (web sign-in goes
    // through the GIS button, not through our request() call, so _state
    // would otherwise stay 'denied' even after a successful sign-in).
    final liveState = {
      ..._state,
      AppPermission.driveSync: app.driveSignedIn
          ? PermissionOutcome.granted
          : (_state[AppPermission.driveSync] ?? PermissionOutcome.denied),
    };

    // Hide permissions that aren't requestable on this platform (e.g.
    // notifications on web) — there's nothing for the user to do.
    final visible = PermissionsService.all
        .where((p) => p.availableHere)
        .toList();

    return Dialog(
      backgroundColor: AppColors.zinc900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Permissions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Xenon54 Universal Tracker works fully offline. These unlock optional features '
                "— grant whatever you'd like.",
                style: TextStyle(fontSize: 12, color: AppColors.zinc500),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No runtime permissions are needed on this platform.',
                    style: TextStyle(fontSize: 12, color: AppColors.zinc500),
                  ),
                )
              else
                for (final p in visible) ...[
                  _PermissionRow(
                    permission: p,
                    outcome: liveState[p] ?? PermissionOutcome.denied,
                    busy: _busy,
                    onGrant: () => _grantOne(p),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      widget.firstLaunch ? 'Skip' : 'Close',
                      style: const TextStyle(color: AppColors.zinc400),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (visible.isNotEmpty && !kIsWeb)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.cyan500,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _busy ? null : _grantAll,
                      child: Text(_busy ? 'Requesting…' : 'Grant all'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final AppPermission permission;
  final PermissionOutcome outcome;
  final bool busy;
  final VoidCallback onGrant;

  const _PermissionRow({
    required this.permission,
    required this.outcome,
    required this.busy,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    final granted = outcome == PermissionOutcome.granted;
    // On web, Google Identity Services blocks programmatic sign-in: the user
    // must click Google's rendered button. Swap the "Grant" text button for
    // the GIS button on that row only. Native platforms keep the normal flow.
    final useGisButton =
        kIsWeb && permission == AppPermission.driveSync && !granted;
    final Widget? gisButton = useGisButton ? driveWebButton() : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: surfaceCard(),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.a(
                granted ? AppColors.emerald400 : AppColors.cyan500,
                0.15,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              granted ? Icons.check : _iconFor(permission),
              size: 18,
              color: granted ? AppColors.emerald400 : AppColors.cyan300,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  permission.rationale,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (gisButton != null)
            // GIS button sizes itself; constrain so the dialog stays compact.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180, maxHeight: 40),
              child: gisButton,
            )
          else
            TextButton(
              onPressed: busy || granted ? null : onGrant,
              style: TextButton.styleFrom(
                foregroundColor: granted
                    ? AppColors.emerald400
                    : AppColors.cyan300,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                granted ? 'Granted' : 'Grant',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static IconData _iconFor(AppPermission p) => switch (p) {
    AppPermission.notifications => Icons.notifications_active_outlined,
    AppPermission.microphone => Icons.mic_none_outlined,
    AppPermission.driveSync => Icons.cloud_outlined,
  };
}
