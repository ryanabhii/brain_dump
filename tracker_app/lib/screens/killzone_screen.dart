import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/suggestions.dart';
import '../models/killzone.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/time_util.dart';
import '../widgets/trading_pnl.dart';
import '../widgets/ui.dart';

/// Port of the React `KillzoneScreen` (Prototype.tsx line 781): trading session
/// windows with live state + countdown, per-session alerts, skip-today, a
/// pre-session checklist, 7-day win/loss stats, the P&L section, and the
/// trade journal.
class KillzoneScreen extends StatefulWidget {
  const KillzoneScreen({super.key});

  @override
  State<KillzoneScreen> createState() => _KillzoneScreenState();
}

class _KillzoneScreenState extends State<KillzoneScreen> {
  DateTime _now = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick so "Live" state + countdowns stay current (like the prototype's
    // setInterval). 20s is plenty for minute-level display.
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

  static Color _kzColor(String name) => switch (name) {
    'amber' => AppColors.amber400,
    'sky' => AppColors.sky400,
    'rose' => AppColors.rose400,
    'violet' => AppColors.violet400,
    'emerald' => AppColors.emerald400,
    _ => AppColors.zinc400,
  };

  String? _expandedKz;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final kzs = [...app.data!.killzones]
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    final cur = nowMin(_now);
    final weekAgo = _now.subtract(const Duration(days: 7));

    ({int w, int l, int? pct}) statsFor(Killzone kz) {
      final recent = kz.journal
          .where((j) => DateTime.parse(j.date).isAfter(weekAgo))
          .toList();
      final w = recent.where((j) => j.result == 'W').length;
      final l = recent.where((j) => j.result == 'L').length;
      return (
        w: w,
        l: l,
        pct: (w + l) > 0 ? (w / (w + l) * 100).round() : null,
      );
    }

    // Flatten journal entries across killzones for the journal section.
    final entries = [
      for (final kz in kzs)
        for (final j in kz.journal) (j: j, kz: kz.name, color: kz.color),
    ]..sort((a, b) => b.j.date.compareTo(a.j.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Fixed header ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Killzones',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Trading sessions · local time',
                      style: TextStyle(fontSize: 13, color: AppColors.zinc500),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                icon: Icons.add,
                onTap: () => _openAddKz(context),
              ),
            ],
          ),
        ),

        // ── Scrollable content ────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              for (final kz in kzs) ...[
                _kzCard(app, kz, cur, statsFor(kz)),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              const TradingPnlSection(),

              const SizedBox(height: 24),
              Row(
                children: [
                  const SectionLabel('Session journal'),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openAddJournal(context),
                    child: const Text(
                      '+ Entry',
                      style: TextStyle(fontSize: 12, color: AppColors.cyan400),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No journal entries yet',
                      style: TextStyle(fontSize: 12, color: AppColors.zinc500),
                    ),
                  ),
                ),
              for (final e in entries.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _journalCard(e.j, e.kz, _kzColor(e.color)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Killzone card ─────────────────────────────────────────
  Widget _kzCard(
    AppState app,
    Killzone kz,
    int cur,
    ({int w, int l, int? pct}) stats,
  ) {
    final c = _kzColor(kz.color);
    final isActive = cur >= kz.startMin && cur < kz.endMin;
    final isPast = cur >= kz.endMin;
    final skipping =
        kz.skipUntil != null && DateTime.parse(kz.skipUntil!).isAfter(_now);
    final tu = timeUntil(kz.startMin, _now);
    final expanded = _expandedKz == kz.id;
    final dimmed = (isPast && !isActive) || skipping;

    return Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.a(c, 0.1)
              : AppColors.a(AppColors.zinc900, 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.a(c, 0.4) : AppColors.zinc800,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              kz.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isActive ? c : AppColors.zinc200,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isActive)
                            Pill('LIVE', fg: c, bg: AppColors.a(c, 0.15)),
                          if (skipping)
                            Pill(
                              'SKIPPED',
                              fg: AppColors.zinc400,
                              bg: AppColors.zinc800,
                            ),
                          const Spacer(),
                          if (stats.pct != null) _statsLabel(stats),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fmtTime(kz.startMin)} – ${fmtTime(kz.endMin)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.zinc500,
                        ),
                      ),
                      if (!isActive && !isPast && !skipping)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'In ${tu.h}h ${tu.m}m',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.zinc400,
                            ),
                          ),
                        ),
                      if (isPast)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.zinc500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => app.toggleKzAlert(kz.id),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kz.alertOn
                          ? AppColors.a(c, 0.1)
                          : AppColors.zinc800,
                    ),
                    child: Icon(
                      kz.alertOn
                          ? Icons.notifications
                          : Icons.notifications_off,
                      size: 14,
                      color: kz.alertOn ? c : AppColors.zinc500,
                    ),
                  ),
                ),
              ],
            ),
            if (kz.alertOn) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const SectionLabel('Alert'),
                  for (final m in const [5, 15, 30])
                    GestureDetector(
                      onTap: () => app.setKzAlertBefore(kz.id, m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kz.alertBefore == m
                              ? AppColors.a(c, 0.15)
                              : AppColors.zinc800,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${m}m',
                          style: TextStyle(
                            fontSize: 11,
                            color: kz.alertBefore == m ? c : AppColors.zinc500,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => app.toggleKzSkipToday(kz.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: skipping ? AppColors.zinc700 : AppColors.zinc800,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skipping ? 'Un-skip' : 'Skip today',
                        style: TextStyle(
                          fontSize: 11,
                          color: skipping
                              ? AppColors.zinc200
                              : AppColors.zinc500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _expandedKz = expanded ? null : kz.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.zinc800,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.checklist,
                            size: 11,
                            color: AppColors.zinc400,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${kz.checklist.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.zinc400,
                            ),
                          ),
                          Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            size: 12,
                            color: AppColors.zinc400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (expanded) ...[
              const Divider(height: 20, color: AppColors.zinc800),
              const SectionLabel('Pre-session checklist'),
              const SizedBox(height: 8),
              if (kz.checklist.isEmpty)
                const Text(
                  'No items.',
                  style: TextStyle(fontSize: 11, color: AppColors.zinc600),
                )
              else
                for (var i = 0; i < kz.checklist.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => app.toggleChecklistItem(kz.id, i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            app.isChecklistDone(kz, i)
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 16,
                            color: app.isChecklistDone(kz, i)
                                ? c
                                : AppColors.zinc600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              kz.checklist[i],
                              style: TextStyle(
                                fontSize: 12,
                                color: app.isChecklistDone(kz, i)
                                    ? AppColors.zinc500
                                    : AppColors.zinc300,
                                decoration: app.isChecklistDone(kz, i)
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statsLabel(({int w, int l, int? pct}) s) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 10, color: AppColors.zinc400),
        children: [
          const TextSpan(text: '7d · '),
          TextSpan(
            text: '${s.w}W',
            style: const TextStyle(color: AppColors.emerald400),
          ),
          const TextSpan(text: '/'),
          TextSpan(
            text: '${s.l}L',
            style: const TextStyle(color: AppColors.rose400),
          ),
          TextSpan(text: ' · ${s.pct}%'),
        ],
      ),
    );
  }

  // ── Journal entry card ────────────────────────────────────
  Widget _journalCard(JournalEntry j, String kzName, Color color) {
    final (badgeBg, badgeFg) = switch (j.result) {
      'W' => (AppColors.a(AppColors.emerald500, 0.2), AppColors.emerald400),
      'L' => (AppColors.a(AppColors.rose500, 0.2), AppColors.rose400),
      _ => (AppColors.zinc800, AppColors.zinc400),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: surfaceCard(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(kzName, style: TextStyle(fontSize: 12, color: color)),
              const SizedBox(width: 8),
              Pill(j.result, fg: badgeFg, bg: badgeBg),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(DateTime.parse(j.date)),
                style: const TextStyle(fontSize: 10, color: AppColors.zinc500),
              ),
            ],
          ),
          if (j.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              j.note,
              style: const TextStyle(fontSize: 12, color: AppColors.zinc300),
            ),
          ],
        ],
      ),
    );
  }

  void _openAddKz(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _KzAddSheet(),
  );

  void _openAddJournal(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _JournalAddSheet(),
  );
}

// ── New killzone sheet ─────────────────────────────────────────
class _KzAddSheet extends StatefulWidget {
  const _KzAddSheet();
  @override
  State<_KzAddSheet> createState() => _KzAddSheetState();
}

class _KzAddSheetState extends State<_KzAddSheet> {
  final _name = TextEditingController();
  TimeOfDay? _start;
  TimeOfDay? _end;
  String _color = 'amber';

  static const _colors = ['amber', 'sky', 'rose', 'violet', 'emerald'];
  static Color _swatch(String n) => switch (n) {
    'amber' => AppColors.amber500,
    'sky' => AppColors.sky400,
    'rose' => AppColors.rose500,
    'violet' => AppColors.violet500,
    _ => AppColors.emerald500,
  };

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty || _start == null || _end == null) return;
    final messenger = ScaffoldMessenger.of(context);
    context.read<AppState>().addKillzone(
      name: name,
      startMin: _start!.hour * 60 + _start!.minute,
      endMin: _end!.hour * 60 + _end!.minute,
      color: _color,
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Killzone added'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Widget _timeButton(String label, TimeOfDay? value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.zinc900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.zinc800),
          ),
          child: Text(
            value == null ? label : value.format(context),
            style: TextStyle(
              fontSize: 14,
              color: value == null ? AppColors.zinc600 : AppColors.zinc100,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'New killzone',
      children: [
        AppAutocompleteField(
          controller: _name,
          hint: 'Session name',
          options: context.read<AppState>().suggestionsFor(
            SuggestionField.session,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _timeButton('Start', _start, () => _pick(true)),
            const SizedBox(width: 8),
            _timeButton('End', _end, () => _pick(false)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final c in _colors)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _swatch(c),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _color == c
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}

// ── New journal entry sheet ────────────────────────────────────
class _JournalAddSheet extends StatefulWidget {
  const _JournalAddSheet();
  @override
  State<_JournalAddSheet> createState() => _JournalAddSheetState();
}

class _JournalAddSheetState extends State<_JournalAddSheet> {
  final _note = TextEditingController();
  String? _kzId;
  String? _result;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_kzId == null || _note.text.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    context.read<AppState>().addJournalEntry(
      kzId: _kzId!,
      result: _result ?? '—',
      note: _note.text.trim(),
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Logged'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kzs = context.read<AppState>().data!.killzones;
    return SheetShell(
      title: 'Journal entry',
      children: [
        const SectionLabel('Session'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kz in kzs)
              GestureDetector(
                onTap: () => setState(() => _kzId = kz.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kzId == kz.id
                        ? AppColors.cyan500
                        : AppColors.zinc900,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _kzId == kz.id
                          ? AppColors.cyan500
                          : AppColors.zinc800,
                    ),
                  ),
                  child: Text(
                    kz.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: _kzId == kz.id
                          ? AppColors.zinc950
                          : AppColors.zinc400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionLabel('Result'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final r in const ['W', 'L', '—'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _result = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _result == r
                            ? (r == 'W'
                                  ? AppColors.emerald500
                                  : r == 'L'
                                  ? AppColors.rose500
                                  : AppColors.zinc700)
                            : AppColors.zinc900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _result == r
                              ? Colors.transparent
                              : AppColors.zinc800,
                        ),
                      ),
                      child: Text(
                        r,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _result == r
                              ? (r == 'L' ? Colors.white : AppColors.zinc950)
                              : AppColors.zinc400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _note,
          hint: 'Notes on the session…',
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}
