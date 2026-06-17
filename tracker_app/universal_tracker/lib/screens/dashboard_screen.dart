import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/format.dart';
import '../utils/time_util.dart';
import '../widgets/ui.dart';

/// Catalog of every dashboard tile, in canonical layout order. The dashboard
/// renders tiles whose [key] is in `profile.pinnedHomeTiles` in this order;
/// the edit sheet lists them in this order too.
class HomeTileSpec {
  final String key; // stable id persisted in Profile.pinnedHomeTiles
  final String label; // shown in the edit sheet
  final IconData icon; // shown in the edit sheet
  const HomeTileSpec({
    required this.key,
    required this.label,
    required this.icon,
  });
}

const List<HomeTileSpec> kHomeTiles = [
  HomeTileSpec(
    key: 'killzone',
    label: 'Killzone hero',
    icon: Icons.trending_up,
  ),
  HomeTileSpec(
    key: 'spend',
    label: 'Monthly spend',
    icon: Icons.account_balance_wallet,
  ),
  HomeTileSpec(
    key: 'apiBurn',
    label: 'API burn',
    icon: Icons.local_fire_department,
  ),
  HomeTileSpec(
    key: 'capture',
    label: 'Capture · open items',
    icon: Icons.psychology_alt,
  ),
  HomeTileSpec(
    key: 'household',
    label: 'Household · groceries',
    icon: Icons.inventory_2,
  ),
  HomeTileSpec(
    key: 'streak',
    label: 'Streak',
    icon: Icons.local_fire_department,
  ),
  HomeTileSpec(
    key: 'body',
    label: 'Body · macros',
    icon: Icons.fitness_center,
  ),
  HomeTileSpec(
    key: 'quickDump',
    label: 'Quick brain dump',
    icon: Icons.auto_awesome,
  ),
];

/// Port of the React `DashboardScreen` (Prototype.tsx line 568): a summary that
/// reads from every section. Cards tap through to their tab via [onNavigate].
/// Each tile can be hidden by the user via the header's edit button.
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
    // Personalise the greeting when the user has set a name; falls back to a
    // bare "Good morning" so the empty-state still reads naturally.
    final name = data.profile.displayName.trim();
    final greetingLine = name.isEmpty ? greeting : '$greeting, $name';

    // Build every tile widget unconditionally; we filter by visibility
    // below. This keeps the per-tile [Pressable] animation controllers
    // alive even when their neighbour is toggled, which avoids the visible
    // flicker that came from tearing a tile down + rebuilding it at a
    // different position in the widget tree.
    final enabled = data.profile.pinnedHomeTiles.toSet();
    final tiles = <String, Widget>{
      'killzone': _killzoneHero(active, upcoming),
      'spend': _StatCard(
        icon: Icons.account_balance_wallet,
        iconColor: AppColors.rose400,
        label: 'Monthly',
        value: '\$${monthly.toStringAsFixed(2)}',
        sub: renewSoon > 0 ? '$renewSoon renew soon' : 'On track',
        subColor: renewSoon > 0 ? AppColors.amber400 : null,
        onTap: () => widget.onNavigate(2),
      ),
      'apiBurn': _apiBurnCard(highBurn),
      'capture': _StatCard(
        icon: Icons.psychology_alt,
        iconColor: AppColors.violet400,
        label: 'Capture',
        value: '$pendingDumps',
        sub: 'Open items',
        onTap: () => widget.onNavigate(3),
      ),
      'household': _StatCard(
        icon: Icons.inventory_2,
        iconColor: AppColors.emerald400,
        label: 'Household',
        value: '$groceryPending',
        sub: lowStock > 0 ? '$lowStock low stock' : 'On list',
        subColor: lowStock > 0 ? AppColors.amber400 : null,
        onTap: () => widget.onNavigate(4),
      ),
      'streak': _StatCard(
        icon: Icons.local_fire_department,
        iconColor: AppColors.orange400,
        label: 'Streak',
        value: '${app.currentStreak} days',
        sub: 'Workout or meal logged',
        onTap: () => widget.onNavigate(5),
      ),
      'body': _bodyCard(body),
      'quickDump': _quickDumpTile(),
    };

    // Canonical row layout. Each entry is either:
    //   - a single-tile row (full width), or
    //   - a pair-tile row (two halves, ALWAYS rendered as a Row with two
    //     Expanded slots even if one slot is hidden, so the surviving tile
    //     keeps its element position across toggles).
    const layout = <(String, String?)>[
      ('killzone', null),
      ('spend', 'apiBurn'),
      ('capture', 'household'),
      ('streak', 'body'),
      ('quickDump', null),
    ];

    final body0 = <Widget>[];
    for (final row in layout) {
      final leftKey = row.$1;
      final rightKey = row.$2;
      final leftOn = enabled.contains(leftKey);
      final rightOn = rightKey != null && enabled.contains(rightKey);
      if (!leftOn && !rightOn) continue;
      Widget rowWidget;
      if (rightKey == null) {
        // Solo full-width tile.
        rowWidget = tiles[leftKey]!;
      } else {
        // Always a two-Expanded Row, even when one slot is empty — the
        // surviving tile's Element position is preserved across toggles, so
        // its Pressable's AnimationController isn't re-created (which was
        // the cause of the flicker). The trick is the `flex: 0` on the
        // hidden side plus an animated gap, so a solo tile still grows to
        // full width without the tree changing shape.
        rowWidget = AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Row(
            children: [
              Expanded(
                flex: leftOn ? 1 : 0,
                child: leftOn ? tiles[leftKey]! : const SizedBox.shrink(),
              ),
              // Gap collapses to zero when one side is hidden, so the
              // surviving tile fills the row edge-to-edge.
              SizedBox(width: (leftOn && rightOn) ? 12 : 0),
              Expanded(
                flex: rightOn ? 1 : 0,
                child: rightOn ? tiles[rightKey]! : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }
      if (body0.isNotEmpty) body0.add(const SizedBox(height: 12));
      body0.add(rowWidget);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar opener — top-left of the dashboard. Uses Scaffold.of
            // (the RootShell's scaffold) so it always finds the drawer that
            // owns every tab.
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: RoundIconButton(
                icon: Icons.menu_rounded,
                onTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(greetIcon, size: 12, color: AppColors.zinc500),
                      const SizedBox(width: 6),
                      Text(
                        greetingLine,
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
            // Edit tiles — opens the sheet to toggle which tiles are visible.
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: RoundIconButton(
                icon: Icons.tune_rounded,
                onTap: () => _openEditTiles(context),
              ),
            ),
            RoundIconButton(
              icon: Icons.settings,
              onTap: () => widget.onNavigate(6),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (body0.isEmpty)
          _EmptyDashboardHint(onEdit: () => _openEditTiles(context))
        else
          ...body0,
      ],
    );
  }

  // ── Per-tile builders ──────────────────────────────────────────────────

  Widget _killzoneHero(dynamic active, dynamic upcoming) {
    return Pressable(
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
          color: active == null ? AppColors.a(AppColors.zinc900, 0.8) : null,
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
                active.name as String,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'In progress · ends ${fmtTime(active.endMin as int)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.zinc400,
                ),
              ),
            ] else if (upcoming != null) ...[
              Text(
                upcoming.name as String,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Builder(
                builder: (_) {
                  final tu = timeUntil(upcoming.startMin as int, _now);
                  return Text(
                    'Opens in ${tu.h}h ${tu.m}m · ${fmtTime(upcoming.startMin as int)}',
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
    );
  }

  Widget _apiBurnCard(dynamic highBurn) => _StatCard(
    icon: Icons.local_fire_department,
    iconColor: AppColors.orange400,
    label: 'API burn',
    value: highBurn != null
        ? '${(((highBurn.apiUsed ?? 0) as num) / ((highBurn.apiCap ?? 1) as num) * 100).round()}%'
        : 'OK',
    sub: highBurn != null ? highBurn.name as String : 'All within budget',
    valueColor: highBurn == null ? AppColors.emerald400 : null,
    onTap: () => widget.onNavigate(2),
  );

  Widget _bodyCard(dynamic body) => _StatCard(
    icon: Icons.fitness_center,
    iconColor: AppColors.cyan400,
    label: 'Body',
    value:
        '${(body.macros.calories.used as num).round()} / ${(body.macros.calories.goal as num).round()}',
    sub: '${(body.macros.protein.used as num).round()}g protein',
    onTap: () => widget.onNavigate(5),
  );

  Widget _quickDumpTile() => Pressable(
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
            child: Icon(Icons.auto_awesome, size: 18, color: Colors.white),
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
  );

  void _openEditTiles(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditTilesSheet(),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────

class _EmptyDashboardHint extends StatelessWidget {
  final VoidCallback onEdit;
  const _EmptyDashboardHint({required this.onEdit});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: surfaceCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.dashboard_customize_outlined,
                size: 16, color: AppColors.cyan400),
            SizedBox(width: 8),
            Text(
              'No tiles to show',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.zinc100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'You hid every dashboard tile. Pick which ones you want back.',
          style: TextStyle(fontSize: 12, color: AppColors.zinc400, height: 1.4),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Edit tiles'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan500,
              foregroundColor: AppColors.zinc950,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Edit tiles sheet ─────────────────────────────────────────────────────

class _EditTilesSheet extends StatelessWidget {
  const _EditTilesSheet();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final enabled = app.data!.profile.pinnedHomeTiles.toSet();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.zinc950,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.zinc800)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.zinc700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Edit dashboard tiles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toggle which summary tiles show on Home.',
              style: TextStyle(fontSize: 12, color: AppColors.zinc500),
            ),
            const SizedBox(height: 14),
            for (final spec in kHomeTiles)
              _TileToggleRow(
                spec: spec,
                enabled: enabled.contains(spec.key),
                onToggle: () => app.toggleHomeTile(spec.key),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyan300,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileToggleRow extends StatelessWidget {
  final HomeTileSpec spec;
  final bool enabled;
  final VoidCallback onToggle;
  const _TileToggleRow({
    required this.spec,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.a(AppColors.cyan500, 0.08)
              : AppColors.a(AppColors.zinc100, 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? AppColors.a(AppColors.cyan500, 0.3)
                : AppColors.zinc800,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.a(
                  enabled ? AppColors.cyan500 : AppColors.zinc100,
                  enabled ? 0.18 : 0.05,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                spec.icon,
                size: 16,
                color: enabled ? AppColors.cyan300 : AppColors.zinc400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                spec.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.zinc100 : AppColors.zinc400,
                ),
              ),
            ),
            // Native-ish Switch reads as the standard "toggle" affordance.
            Switch(
              value: enabled,
              onChanged: (_) => onToggle(),
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.cyan500,
              inactiveTrackColor: AppColors.zinc800,
              inactiveThumbColor: AppColors.zinc600,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
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
