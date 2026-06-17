import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/drive_web_button.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../sync/remote_store.dart';
import '../sync/sync_tabs.dart';
import '../theme/colors.dart';
import '../widgets/permissions_dialog.dart';
import '../widgets/ui.dart';
import '../widgets/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'templates_screen.dart';

/// Port of the React `ProfileScreen` (Prototype.tsx line 2557): reminder
/// settings, household members, and data actions (copy backup + reset).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.data!;
    final notif = data.profile.notifications;
    final master = notif.master;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Fixed header ──────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Reminders · household · data',
                style: TextStyle(fontSize: 13, color: AppColors.zinc500),
              ),
            ],
          ),
        ),

        // ── Scrollable content ────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Identity card — tap to open Edit profile.
              GestureDetector(
                onTap: () => EditProfileScreen.show(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: surfaceCard(),
                  child: Row(
                    children: [
                      _IdentityAvatar(profile: data.profile),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.profile.displayName.isEmpty
                                  ? 'Add your name'
                                  : data.profile.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: data.profile.displayName.isEmpty
                                    ? AppColors.zinc500
                                    : AppColors.zinc100,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _identitySubtitle(app),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.zinc500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.zinc500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Killzone reminders ──
              const SectionLabel('Killzone reminders'),
              const SizedBox(height: 8),
              Container(
                decoration: surfaceCard(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All alerts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Master switch for every reminder',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.zinc500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: master,
                            onChanged: app.setNotifMaster,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.cyan500,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.zinc800),
                    Opacity(
                      opacity: master ? 1 : 0.4,
                      child: IgnorePointer(
                        ignoring: !master,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionLabel('Default lead-time'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      for (final m in const [5, 15, 30])
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: _Chip(
                                            label: '$m min',
                                            active: notif.leadTime == m,
                                            onTap: () => app.setLeadTime(m),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.zinc800),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionLabel('Quiet hours'),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _TimeButton(
                                        value: notif.quietStart,
                                        onPicked: app.setQuietStart,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'to',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.zinc500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _TimeButton(
                                        value: notif.quietEnd,
                                        onPicked: app.setQuietEnd,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: Notifications.supported
                                  ? GestureDetector(
                                      onTap: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final granted =
                                            await Notifications.requestPermission();
                                        if (granted) {
                                          await Notifications.reschedule(data);
                                        }
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              granted
                                                  ? 'Notifications enabled'
                                                  : 'Permission denied',
                                            ),
                                            duration: const Duration(
                                              milliseconds: 1400,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.a(
                                            AppColors.cyan500,
                                            0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: AppColors.a(
                                              AppColors.cyan500,
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Enable notifications',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cyan300,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Notifications aren't available on web — "
                                      'run on a device to enable them.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.zinc600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Daily review ──
              const SectionLabel('Daily review'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: surfaceCard(),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review reminder',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'A daily nudge to review your day',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.zinc500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TimeButton(
                      value: data.profile.dailyReviewTime,
                      onPicked: app.setDailyReviewTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Help ──
              const SectionLabel('Help'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => WelcomeScreen.show(
                  context,
                  onDone: () => app.markWelcomeSeen(),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: surfaceCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.a(AppColors.cyan500, 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          size: 18,
                          color: AppColors.cyan300,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Show welcome',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Replay the walkthrough for every tab',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.zinc500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.zinc500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Templates ──
              const SectionLabel('Templates'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => TemplatesScreen.show(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: surfaceCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.a(AppColors.amber400, 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bookmark_border,
                          size: 18,
                          color: AppColors.amber400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manage templates',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _templatesSubtitle(data),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.zinc500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.zinc500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Permissions ──
              const SectionLabel('Permissions'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => PermissionsDialog.show(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: surfaceCard(),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.a(AppColors.cyan500, 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppColors.cyan300,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Request all permissions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Notifications and Google Drive sign-in',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.zinc500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.zinc500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Household ──
              const SectionLabel('Household'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: surfaceCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final m in data.groceries.members)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.zinc800,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.zinc300,
                                  ),
                                ),
                                if (data.groceries.members.length > 1) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => app.removeMember(m),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: AppColors.zinc500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _addMember(context, app),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.a(AppColors.cyan500, 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.a(AppColors.cyan500, 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 12,
                                  color: AppColors.cyan300,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.cyan300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Data ──
              const SectionLabel('Data'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final json = const JsonEncoder.withIndent(
                    '  ',
                  ).convert(data.toJson());
                  Clipboard.setData(ClipboardData(text: json));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Backup JSON copied to clipboard'),
                        duration: Duration(milliseconds: 1400),
                      ),
                    );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: surfaceCard(),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Copy data (JSON)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Copies a full backup of your data to the clipboard',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmReset(context, app),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: surfaceCard(
                    ring: AppColors.a(AppColors.rose500, 0.4),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset to defaults',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose400,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Clears all local data',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Google Drive sync ──
              const SectionLabel('Google Drive sync'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: surfaceCard(),
                child: app.driveSignedIn
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed in as ${app.driveEmail ?? ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (app.lastSyncAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Last sync · ${_hhmm(app.lastSyncAt!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.zinc500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _PillButton(
                                  label: 'Back up',
                                  filled: true,
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final msg = await app.driveBackup();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        duration: const Duration(
                                          milliseconds: 1400,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PillButton(
                                  label: 'Restore',
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: AppColors.zinc900,
                                        title: const Text(
                                          'Restore from Drive?',
                                        ),
                                        content: const Text(
                                          'This overwrites your local data with the '
                                          'Drive backup.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Restore'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok != true) return;
                                    final msg = await app.driveRestore();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        duration: const Duration(
                                          milliseconds: 1400,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.zinc800),
                          const SizedBox(height: 12),
                          const SectionLabel('Multi-user sync'),
                          const SizedBox(height: 6),
                          Text(
                            app.syncConflicts > 0
                                ? '${app.syncConflicts} item(s) kept on both sides — review duplicates'
                                : 'Share tabs with others; changes sync every ~15s.',
                            style: TextStyle(
                              fontSize: 11,
                              color: app.syncConflicts > 0
                                  ? AppColors.amber400
                                  : AppColors.zinc500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _PillButton(
                                  label: 'Sync now',
                                  filled: true,
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final msg = await app.syncNow();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        duration: const Duration(
                                          milliseconds: 1400,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PillButton(
                                  label: 'Shared tabs',
                                  onTap: () => _openSharing(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => app.driveSignOut(),
                            child: const Text(
                              'Sign out',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.zinc500,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in to back up & restore your data through your own '
                            'Google Drive (no server involved).',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.zinc400,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Web requires Google's rendered button; native platforms
                          // use the normal sign-in flow.
                          if (kIsWeb)
                            Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  driveWebButton() ?? const SizedBox.shrink(),
                            )
                          else
                            _PillButton(
                              label: 'Sign in with Google',
                              filled: true,
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final ok = await app.driveSignIn();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Signed in to Google'
                                          : 'Sign-in unavailable — check OAuth setup',
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1600,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Tracker · v0.2',
                  style: TextStyle(fontSize: 10, color: AppColors.zinc600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openSharing(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SyncShareSheet(),
    );
  }

  Future<void> _addMember(BuildContext context, AppState app) async {
    // Use a StatefulWidget so the TextEditingController is owned by the widget
    // and disposed only after the dialog's exit animation completes — not
    // immediately after showDialog() returns (which races with the animation).
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (name != null && name.isNotEmpty) app.addMember(name);
  }

  Future<void> _confirmReset(BuildContext context, AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.zinc900,
        title: const Text('Reset everything?'),
        content: const Text(
          'This restores the seed data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.resetToDefaults();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reset to defaults'),
          duration: Duration(milliseconds: 1400),
        ),
      );
    }
  }
}

/// Subtitle under the identity card: combines email / age / timezone in
/// whatever order makes sense given which fields are filled in.
String _identitySubtitle(AppState app) {
  final p = app.data!.profile;
  final parts = <String>[];
  if (p.email.isNotEmpty) parts.add(p.email);
  final age = p.age;
  if (age != null) parts.add('$age yrs');
  parts.add(app.localTimezone);
  return parts.join(' · ');
}

/// "12 templates · meals, workouts" — encourages exploration without a long
/// list of zero-counts.
String _templatesSubtitle(dynamic data) {
  final total = (data.mealTemplates as List).length +
      (data.workoutTemplates as List).length +
      (data.groceryTemplates as List).length +
      (data.pantryTemplates as List).length +
      (data.subscriptionTemplates as List).length +
      (data.killzoneTemplates as List).length +
      (data.flowTemplates as List).length;
  if (total == 0) {
    return 'Pre-saved entries you can apply with one tap';
  }
  return '$total template${total == 1 ? '' : 's'} · tap to manage';
}

/// Round avatar with initials over a gradient of the user's chosen color.
class _IdentityAvatar extends StatelessWidget {
  final dynamic profile; // Profile — kept dynamic to avoid an extra import.
  const _IdentityAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final accent = avatarColorFor(profile.avatarColor as String);
    final initials = profile.initials as String;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, AppColors.a(accent, 0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.a(accent, 0.35),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: accent.computeLuminance() > 0.55
              ? AppColors.zinc950
              : Colors.white,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.a(AppColors.cyan500, 0.2) : AppColors.zinc800,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.a(AppColors.cyan500, 0.4)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? AppColors.cyan300 : AppColors.zinc400,
        ),
      ),
    ),
  );
}

class _TimeButton extends StatelessWidget {
  final String value; // "HH:mm"
  final ValueChanged<String> onPicked;
  const _TimeButton({required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
        );
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          onPicked(
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.zinc800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, color: AppColors.zinc200),
        ),
      ),
    );
  }
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ── Per-tab sharing sheet ──────────────────────────────────────
class _SyncShareSheet extends StatefulWidget {
  const _SyncShareSheet();
  @override
  State<_SyncShareSheet> createState() => _SyncShareSheetState();
}

class _SyncShareSheetState extends State<_SyncShareSheet> {
  @override
  void initState() {
    super.initState();
    // Pull the latest access roles from Drive when the sheet opens.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppState>().refreshRoles(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final roles = app.syncRoles;
    return SheetShell(
      title: 'Shared tabs',
      children: [
        const Text(
          'Each tab syncs as its own Drive file. Sharing grants someone '
          'view-only or edit access to just that tab.',
          style: TextStyle(fontSize: 11, color: AppColors.zinc500),
        ),
        const SizedBox(height: 12),
        for (final tab in kSyncTabs) _tabRow(context, app, tab, roles[tab.key]),
      ],
    );
  }

  Widget _tabRow(
    BuildContext context,
    AppState app,
    SyncTab tab,
    SyncRole? role,
  ) {
    final enabled = role != null && role != SyncRole.none;
    final status = !enabled
        ? 'Not synced'
        : role == SyncRole.editor
        ? 'Syncing · you can edit'
        : 'Shared with you · view-only';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled ? AppColors.emerald400 : AppColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          if (!enabled)
            _PillButton(
              label: 'Enable',
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final msg = await app.enableTab(tab.key);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    duration: const Duration(milliseconds: 1400),
                  ),
                );
              },
            )
          else if (role == SyncRole.editor)
            _PillButton(
              label: 'Manage',
              filled: true,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _ManageAccessSheet(tab),
              ),
            ),
        ],
      ),
    );
  }
}

/// Email + role dialog used to add a collaborator to [tab].
Future<void> _shareDialog(
  BuildContext context,
  AppState app,
  SyncTab tab,
) async {
  // _ShareTabDialog owns its controller so it is disposed with the widget
  // (after the exit animation) rather than immediately when the future resolves.
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<({String email, SyncRole role})>(
    context: context,
    builder: (_) => _ShareTabDialog(tabLabel: tab.label),
  );
  if (result != null && result.email.isNotEmpty) {
    final msg = await app.shareTab(tab.key, result.email, result.role);
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }
}

// ── Manage access (collaborators) for one tab ──────────────────
class _ManageAccessSheet extends StatefulWidget {
  final SyncTab tab;
  const _ManageAccessSheet(this.tab);
  @override
  State<_ManageAccessSheet> createState() => _ManageAccessSheetState();
}

class _ManageAccessSheetState extends State<_ManageAccessSheet> {
  List<Collaborator>? _people; // null = loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final people = await context.read<AppState>().tabCollaborators(
      widget.tab.key,
    );
    if (!mounted) return;
    setState(() => _people = people);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final people = _people;
    return SheetShell(
      title: 'Share · ${widget.tab.label}',
      children: [
        _PillButton(
          label: 'Add person',
          filled: true,
          onTap: () async {
            await _shareDialog(context, app, widget.tab);
            await _load();
          },
        ),
        const SizedBox(height: 12),
        if (people == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Loading…',
                style: TextStyle(color: AppColors.zinc500),
              ),
            ),
          )
        else if (people.isEmpty)
          const Text(
            'No one yet. Add a person to share this tab.',
            style: TextStyle(fontSize: 12, color: AppColors.zinc500),
          )
        else
          for (final c in people) _personRow(app, c),
      ],
    );
  }

  Widget _personRow(AppState app, Collaborator c) {
    Future<void> act(Future<String> Function() op) async {
      final messenger = ScaffoldMessenger.of(context);
      final msg = await op();
      await _load();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1400),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.email,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  c.isOwner
                      ? 'Owner'
                      : c.role == SyncRole.editor
                      ? 'Can edit'
                      : 'View only',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          if (!c.isOwner) ...[
            // Tap to flip the role.
            GestureDetector(
              onTap: () => act(
                () => app.setCollaboratorRole(
                  widget.tab.key,
                  c.permissionId,
                  c.role == SyncRole.editor ? SyncRole.viewer : SyncRole.editor,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.zinc800,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  c.role == SyncRole.editor ? 'Editor' : 'Viewer',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.zinc300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => act(
                () => app.revokeCollaborator(widget.tab.key, c.permissionId),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.zinc500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.a(AppColors.cyan500, 0.15)
            : AppColors.zinc800,
        borderRadius: BorderRadius.circular(10),
        border: filled
            ? Border.all(color: AppColors.a(AppColors.cyan500, 0.3))
            : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: filled ? AppColors.cyan300 : AppColors.zinc300,
        ),
      ),
    ),
  );
}

// ── Add-member dialog ──────────────────────────────────────────
/// Owns its [TextEditingController] so the controller is disposed only after
/// the dialog's exit animation completes, not immediately when [showDialog]
/// resolves (which would race with the animation and crash on rebuild).
class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.zinc900,
      title: const Text('Add member'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: AppColors.zinc100),
        decoration: const InputDecoration(
          hintText: 'Name',
          hintStyle: TextStyle(color: AppColors.zinc600),
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// ── Share-tab dialog ───────────────────────────────────────────
/// Owns its [TextEditingController] for the same reason as [_AddMemberDialog].
class _ShareTabDialog extends StatefulWidget {
  final String tabLabel;
  const _ShareTabDialog({required this.tabLabel});

  @override
  State<_ShareTabDialog> createState() => _ShareTabDialogState();
}

class _ShareTabDialogState extends State<_ShareTabDialog> {
  final _controller = TextEditingController();
  SyncRole _role = SyncRole.editor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.zinc900,
      title: Text('Share ${widget.tabLabel}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.zinc100),
            decoration: const InputDecoration(
              hintText: 'their@gmail.com',
              hintStyle: TextStyle(color: AppColors.zinc600),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final r in const [SyncRole.editor, SyncRole.viewer])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _role = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _role == r
                            ? AppColors.a(AppColors.cyan500, 0.2)
                            : AppColors.zinc800,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _role == r
                              ? AppColors.a(AppColors.cyan500, 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        r == SyncRole.editor ? 'Can edit' : 'View only',
                        style: TextStyle(
                          fontSize: 12,
                          color: _role == r
                              ? AppColors.cyan300
                              : AppColors.zinc400,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            (email: _controller.text.trim(), role: _role),
          ),
          child: const Text('Share'),
        ),
      ],
    );
  }
}
