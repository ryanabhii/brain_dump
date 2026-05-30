import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/format.dart';
import '../utils/time_util.dart';
import '../widgets/ui.dart';

/// Port of the React `DashboardScreen` (Prototype.tsx line 568): a summary that
/// reads from every section. Cards tap through to their tab via [onNavigate].
class DashboardScreen extends StatefulWidget {
  /// Switch the bottom-nav tab (indexes match RootShell's screen list).
  final void Function(int index) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 20),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.data!;
    final hour = _now.hour;
    final cur = nowMin(_now);

    // Next / live killzone.
    final sorted = [...data.killzones]
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    final activeList = sorted
        .where((k) => cur >= k.startMin && cur < k.endMin)
        .toList();
    final active = activeList.isEmpty ? null : activeList.first;
    final upList = sorted.where((k) => k.startMin > cur).toList();
    final upcoming = upList.isNotEmpty
        ? upList.first
        : (sorted.isNotEmpty ? sorted.first : null);

    final monthly = data.subscriptions.fold<double>(0, (s, x) => s + x.cost);
    final renewSoon = data.subscriptions
        .where((s) => daysUntil(s.nextRenewal) <= 3)
        .length;
    final highList = data.subscriptions
        .where(
          (s) => s.type == 'api' && (s.apiUsed ?? 0) / (s.apiCap ?? 1) > 0.65,
        )
        .toList();
    final highBurn = highList.isEmpty ? null : highList.first;
    final pendingDumps = data.braindumps.where((b) => !b.completed).length;
    final lowStock = data.groceries.pantry.where((p) => p.isLow).length;
    final groceryPending = data.groceries.list
        .where((g) => !g.completed)
        .length;
    final body = data.body;

    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final greetIcon = hour < 12
        ? Icons.coffee
        : hour < 17
        ? Icons.wb_sunny
        : Icons.nightlight;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(greetIcon, size: 12, color: AppColors.zinc500),
                      const SizedBox(width: 6),
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Today's tracker",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            RoundIconButton(
              icon: Icons.settings,
              onTap: () => widget.onNavigate(6),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Killzone hero
        Pressable(
          onTap: () => widget.onNavigate(1),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active != null
                    ? AppColors.a(AppColors.rose500, 0.3)
                    : AppColors.zinc800,
              ),
              gradient: active != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.a(AppColors.rose500, 0.2),
                        Colors.transparent,
                      ],
                    )
                  : null,
              color: active == null
                  ? AppColors.a(AppColors.zinc900, 0.8)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: active != null
                          ? AppColors.rose400
                          : AppColors.zinc400,
                    ),
                    const SizedBox(width: 6),
                    SectionLabel(
                      active != null ? 'Live session' : 'Next killzone',
                      color: active != null
                          ? AppColors.rose400
                          : AppColors.zinc400,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (active != null) ...[
                  Text(
                    active.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'In progress · ends ${fmtTime(active.endMin)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.zinc400,
                    ),
                  ),
                ] else if (upcoming != null) ...[
                  Text(
                    upcoming.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final tu = timeUntil(upcoming.startMin, _now);
                      return Text(
                        'Opens in ${tu.h}h ${tu.m}m · ${fmtTime(upcoming.startMin)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.zinc400,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stat grid (2 columns)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet,
                iconColor: AppColors.rose400,
                label: 'Monthly',
                value: '\$${monthly.toStringAsFixed(2)}',
                sub: renewSoon > 0 ? '$renewSoon renew soon' : 'On track',
                subColor: renewSoon > 0 ? AppColors.amber400 : null,
                onTap: () => widget.onNavigate(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                iconColor: AppColors.orange400,
                label: 'API burn',
                value: highBurn != null
                    ? '${((highBurn.apiUsed ?? 0) / (highBurn.apiCap ?? 1) * 100).round()}%'
                    : 'OK',
                sub: highBurn != null ? highBurn.name : 'All within budget',
                valueColor: highBurn == null ? AppColors.emerald400 : null,
                onTap: () => widget.onNavigate(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.psychology_alt,
                iconColor: AppColors.violet400,
                label: 'Capture',
                value: '$pendingDumps',
                sub: 'Open items',
                onTap: () => widget.onNavigate(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2,
                iconColor: AppColors.emerald400,
                label: 'Household',
                value: '$groceryPending',
                sub: lowStock > 0 ? '$lowStock low stock' : 'On list',
                subColor: lowStock > 0 ? AppColors.amber400 : null,
                onTap: () => widget.onNavigate(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department,
                iconColor: AppColors.orange400,
                label: 'Streak',
                value: '${app.currentStreak} days',
                sub: 'Workout or meal logged',
                onTap: () => widget.onNavigate(5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.fitness_center,
                iconColor: AppColors.cyan400,
                label: 'Body',
                value:
                    '${body.macros.calories.used.round()} / ${body.macros.calories.goal.round()}',
                sub: '${body.macros.protein.used.round()}g protein',
                onTap: () => widget.onNavigate(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick brain dump
        Pressable(
          onTap: () => widget.onNavigate(3),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.violet500, Color(0xFF4F46E5)],
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick brain dump',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap to capture a thought',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;
  final Color? subColor;
  final Color? valueColor;
  final VoidCallback onTap;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
    this.subColor,
    this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: surfaceCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: iconColor),
                const SizedBox(width: 6),
                SectionLabel(label),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.zinc100,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: subColor ?? AppColors.zinc500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
