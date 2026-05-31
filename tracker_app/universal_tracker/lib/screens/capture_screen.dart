import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/default_data.dart';
import '../models/brain_dump.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/auto_route.dart';
import '../widgets/ui.dart';

/// Port of the React `BrainScreen` (Prototype.tsx line 1317): capture quick
/// thoughts, filter open/done/all, and (the improvement) promote a dump that
/// looks like a shopping item straight into the grocery list.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  String _filter = 'open'; // open | done | all

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.data!.braindumps.where((b) {
      return switch (_filter) {
        'open' => !b.completed,
        'done' => b.completed,
        _ => true,
      };
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capture',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Brain dumps · single tap',
                style: TextStyle(fontSize: 13, color: AppColors.zinc500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ActionCard(
            icon: Icons.mic,
            title: 'Quick dump',
            subtitle: 'Text note',
            tint: AppColors.violet500,
            onTap: () => _openAdd(context),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final f in const ['open', 'done', 'all'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: f[0].toUpperCase() + f.substring(1),
                    active: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _filter == 'open' ? 'All clear ✨' : 'Nothing here',
                    style: const TextStyle(color: AppColors.zinc500),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _DumpCard(item: items[i]),
                ),
        ),
      ],
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BrainAddSheet(),
    );
  }
}

(Color, Color) _tagColors(String tag) => switch (tag) {
  'trading' => (AppColors.a(AppColors.amber500, 0.15), AppColors.amber400),
  'idea' => (AppColors.a(AppColors.violet500, 0.15), AppColors.violet400),
  'work' => (AppColors.a(AppColors.sky400, 0.15), AppColors.sky400),
  _ => (AppColors.a(AppColors.rose400, 0.15), AppColors.rose400),
};

class _DumpCard extends StatelessWidget {
  final BrainDump item;
  const _DumpCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final (tagBg, tagFg) = _tagColors(item.tag);
    final dest = item.completed ? null : autoRoute(item.text);
    final created = DateFormat('MMM d').format(DateTime.parse(item.createdAt));

    return Opacity(
      opacity: item.completed ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: surfaceCard(radius: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => app.toggleDump(item.id),
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.completed ? AppColors.violet500 : null,
                  border: Border.all(
                    color: item.completed
                        ? AppColors.violet500
                        : AppColors.zinc600,
                  ),
                ),
                child: item.completed
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.completed
                          ? AppColors.zinc500
                          : AppColors.zinc100,
                      decoration: item.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(item.tag, fg: tagFg, bg: tagBg),
                      if (item.reminderAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications,
                              size: 10,
                              color: AppColors.amber400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              DateFormat(
                                'MMM d',
                              ).format(DateTime.parse(item.reminderAt!)),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.amber400,
                              ),
                            ),
                          ],
                        ),
                      if (dest == 'grocery')
                        GestureDetector(
                          onTap: () {
                            app.moveDumpToGrocery(item);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Moved to grocery list'),
                                  duration: Duration(milliseconds: 1200),
                                ),
                              );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.a(AppColors.emerald500, 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.a(AppColors.emerald500, 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 10,
                                  color: AppColors.emerald400,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Move to Grocery',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.emerald400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (dest != null)
                        Text(
                          'looks like · $dest',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.zinc500,
                          ),
                        ),
                      Text(
                        created,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => app.removeDump(item.id),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.zinc600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small building blocks ──────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.a(tint, 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.a(tint, 0.25), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.zinc400),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.zinc100 : AppColors.zinc900,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.zinc100 : AppColors.zinc800,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: active ? AppColors.zinc900 : AppColors.zinc400,
        ),
      ),
    ),
  );
}

// ── Add sheet ──────────────────────────────────────────────────
class _BrainAddSheet extends StatefulWidget {
  const _BrainAddSheet();
  @override
  State<_BrainAddSheet> createState() => _BrainAddSheetState();
}

class _BrainAddSheetState extends State<_BrainAddSheet> {
  final _text = TextEditingController();
  String? _tag;
  int? _reminderIdx;

  static const _reminders = <(String, num)>[
    ('Later today', 0.25),
    ('Tomorrow', 1),
    ('Next week', 7),
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final reminderAt = _reminderIdx == null
        ? null
        : todayPlus(_reminders[_reminderIdx!].$2);
    context.read<AppState>().addDump(
      text: text,
      tag: _tag,
      reminderAt: reminderAt,
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Captured ✨'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Brain dump',
      children: [
        AppTextField(
          controller: _text,
          hint: "What's on your mind?",
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        const SectionLabel('Tag'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in const ['personal', 'work', 'trading', 'idea'])
              _ChoiceChip(
                label: t,
                active: _tag == t,
                onTap: () => setState(() => _tag = t),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionLabel('Remind me'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _reminders.length; i++)
              _ChoiceChip(
                label: _reminders[i].$1,
                active: _reminderIdx == i,
                // Improvement over the prototype: select by index, so the
                // highlight is reliable (the prototype compared freshly-made
                // timestamps, which never matched — Prototype.tsx line 2942).
                onTap: () =>
                    setState(() => _reminderIdx = _reminderIdx == i ? null : i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.violet500 : AppColors.zinc900,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.violet500 : AppColors.zinc800,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.white : AppColors.zinc400,
        ),
      ),
    ),
  );
}
