import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/suggestions.dart';
import '../models/subscription.dart';
import '../models/templates.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/format.dart';
import '../utils/grouping.dart';
import '../widgets/save_as_template_toggle.dart';
import '../widgets/template_picker.dart';
import '../widgets/ui.dart';

/// Port of the React `SubsScreen` (Prototype.tsx line 1144):
/// monthly total, per-category breakdown, API-burn meters, and the
/// subscription list with "used this month" toggle + delete.
class SpendScreen extends StatelessWidget {
  const SpendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `watch` rebuilds this screen whenever AppState changes (add/remove/toggle).
    final app = context.watch<AppState>();
    final subs = app.data!.subscriptions;

    final monthly = subs.fold<double>(0, (sum, s) => sum + s.cost);
    final annual = monthly * 12;
    final apis = subs.where((s) => s.type == 'api').toList();
    final flat = subs.where((s) => s.type == 'subscription').toList();

    // Aggregate spend by category (case-insensitive), sorted high → low.
    final catEntries =
        groupByCaseInsensitive<Subscription>(subs, (s) => s.category).entries
            .map(
              (e) => MapEntry(
                e.key,
                e.value.fold<double>(0, (sum, s) => sum + s.cost),
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spend',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Subscriptions & API burn',
                      style: TextStyle(fontSize: 13, color: AppColors.zinc500),
                    ),
                  ],
                ),
              ),
              _AddButton(onTap: () => _openAddSheet(context)),
            ],
          ),
        ),

        // ── Scrollable content ────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _monthlyCard(monthly, annual, subs.length, apis.length),
              if (catEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                _categoryCard(catEntries, monthly),
              ],
              if (apis.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionLabel('API Burn', color: AppColors.orange400),
                const SizedBox(height: 12),
                for (final s in apis) ...[
                  _ApiBurnCard(sub: s),
                  const SizedBox(height: 12),
                ],
              ],
              const SizedBox(height: 12),
              const SectionLabel('Subscriptions'),
              const SizedBox(height: 12),
              for (final s in flat) ...[
                _SubscriptionCard(sub: s),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Monthly total (gradient hero card) ──────────────────────
  Widget _monthlyCard(double monthly, double annual, int count, int apiCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.a(AppColors.rose500, 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.a(AppColors.rose600, 0.3),
            AppColors.a(AppColors.rose500, 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Monthly total', color: AppColors.rose300),
          const SizedBox(height: 4),
          Text(
            '\$${monthly.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$count active · $apiCount API   ·   ~ \$${annual.toStringAsFixed(0)}/yr',
            style: const TextStyle(fontSize: 12, color: AppColors.zinc400),
          ),
        ],
      ),
    );
  }

  // ── Per-category breakdown ──────────────────────────────────
  Widget _categoryCard(List<MapEntry<String, double>> entries, double monthly) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('By category'),
          const SizedBox(height: 12),
          for (final e in entries) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.zinc300,
                    ),
                  ),
                ),
                Text(
                  '\$${e.value.toStringAsFixed(2)}  ·  ${(e.value / monthly * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.zinc400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ProgressBar(
              value: e.value / monthly,
              color: AppColors.rose400,
              height: 4,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSubscriptionSheet(),
    );
  }
}

// ── API burn meter card ───────────────────────────────────────
class _ApiBurnCard extends StatelessWidget {
  final Subscription sub;
  const _ApiBurnCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final used = sub.apiUsed ?? 0;
    final cap = sub.apiCap ?? 1;
    final pct = math.min(100, used / cap * 100);
    final renewIn = daysUntil(sub.nextRenewal);
    final elapsedDays = math.max(1, 30 - renewIn);
    final burnRate = used / elapsedDays;
    final willDeplete = burnRate > 0 ? ((cap - used) / burnRate).ceil() : 999;
    final depletes = willDeplete < renewIn;

    final Color barColor = pct > 80
        ? AppColors.rose500
        : pct > 65
        ? AppColors.amber500
        : AppColors.emerald500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(),
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
                    Text(
                      sub.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${sub.cost.toStringAsFixed(0)}/mo · ${sub.category}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.zinc500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pct.round()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: pct > 65
                          ? AppColors.rose400
                          : AppColors.emerald400,
                    ),
                  ),
                  Text(
                    '\$${used.toStringAsFixed(0)} / \$${cap.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.zinc500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: pct / 100, color: barColor),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Burn: \$${burnRate.toStringAsFixed(2)}/day',
                style: const TextStyle(fontSize: 11, color: AppColors.zinc500),
              ),
              Text(
                depletes ? 'Depletes in ${willDeplete}d' : 'Renews ${renewIn}d',
                style: TextStyle(
                  fontSize: 11,
                  color: depletes ? AppColors.rose400 : AppColors.zinc500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _logUsage(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.zinc800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Log usage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.zinc300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logUsage(BuildContext context) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.zinc900,
        title: Text('Log usage · ${sub.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.zinc100),
          decoration: const InputDecoration(
            hintText: r'Amount spent (e.g. 12.50)',
            hintStyle: TextStyle(color: AppColors.zinc600),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null && amount > 0) {
      app.addApiUsage(sub.id, amount);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Logged \$${amount.toStringAsFixed(2)}'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }
}

// ── Flat subscription row ──────────────────────────────────────
class _SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final d = daysUntil(sub.nextRenewal);
    final idle = daysSince(sub.lastUsedReset);
    final dormant = !sub.usedThisMonth && idle != null && idle >= 30;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: surfaceCard(radius: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          sub.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (d <= 3)
                          Pill(
                            d == 0
                                ? 'TODAY'
                                : d == 1
                                ? 'TOMORROW'
                                : '${d}D',
                            fg: AppColors.amber400,
                            bg: AppColors.a(AppColors.amber500, 0.2),
                          ),
                        if (dormant)
                          Pill(
                            'CONSIDER CANCEL',
                            fg: AppColors.rose400,
                            bg: AppColors.a(AppColors.rose500, 0.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sub.category} · monthly · \$${(sub.cost * 12).toStringAsFixed(0)}/yr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.zinc500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${sub.cost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${d}d',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.zinc500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  app.removeSubscription(sub.id);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Removed'),
                        duration: Duration(milliseconds: 1200),
                      ),
                    );
                },
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.zinc600,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.zinc800),
          Row(
            children: [
              const SectionLabel('Used this month?'),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => app.toggleUsed(sub.id),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: sub.usedThisMonth
                        ? AppColors.a(AppColors.emerald500, 0.2)
                        : AppColors.zinc800,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sub.usedThisMonth ? 'Yes' : 'Not yet',
                    style: TextStyle(
                      fontSize: 11,
                      color: sub.usedThisMonth
                          ? AppColors.emerald400
                          : AppColors.zinc400,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (idle != null)
                Text(
                  'last used ${idle}d ago',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.zinc600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Round "+" header button ────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.zinc900,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.zinc800),
      ),
      child: const Icon(Icons.add, size: 18, color: AppColors.zinc300),
    ),
  );
}

// ── Add-subscription bottom sheet ──────────────────────────────
class _AddSubscriptionSheet extends StatefulWidget {
  const _AddSubscriptionSheet();

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  final _name = TextEditingController();
  final _cost = TextEditingController();
  final _category = TextEditingController();
  final _days = TextEditingController(text: '30');
  String _type = 'subscription';
  bool _alsoTemplate = false;

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _category.dispose();
    _days.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final cost = double.tryParse(_cost.text.trim());
    if (name.isEmpty || cost == null) return;
    // Capture the messenger BEFORE popping — after pop this context is gone.
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final cat = _category.text;
    final cadence = int.tryParse(_days.text.trim()) ?? 30;
    app.addSubscription(
      name: name,
      cost: cost,
      type: _type,
      category: cat,
      days: cadence,
    );
    if (_alsoTemplate) {
      app.saveSubscriptionTemplate(
        SubscriptionTemplate(
          id: app.newTemplateId('st'),
          name: name,
          cost: cost,
          type: _type,
          category: cat.trim().isEmpty ? 'Other' : cat.trim(),
          cadenceDays: cadence,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _alsoTemplate
              ? 'Subscription added · template saved'
              : 'Subscription added',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _applyTemplate(SubscriptionTemplate t) {
    setState(() {
      _name.text = t.name;
      _cost.text = t.cost.toString();
      _category.text = t.category;
      _days.text = t.cadenceDays.toString();
      _type = t.type;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lift the sheet above the keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final app = context.watch<AppState>();
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.zinc950,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.zinc800)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New subscription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TemplatePicker<SubscriptionTemplate>(
              templates: app.data!.subscriptionTemplates,
              accent: AppColors.rose400,
              labelOf: (t) => t.name,
              subtitleOf: (t) => '\$${t.cost.toStringAsFixed(2)} · ${t.type}',
              iconOf: (_) => Icons.credit_card,
              onPick: _applyTemplate,
            ),
            AppAutocompleteField(
              controller: _name,
              hint: 'Name (e.g. Netflix)',
              options: app.suggestionsFor(SuggestionField.subscription),
            ),
            const SizedBox(height: 12),
            _field(
              _cost,
              'Monthly cost',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeButton('subscription', 'Flat subscription'),
                const SizedBox(width: 8),
                _typeButton('api', 'API / metered'),
              ],
            ),
            const SizedBox(height: 12),
            AppAutocompleteField(
              controller: _category,
              hint: 'Category',
              options: app.suggestionsFor(SuggestionField.spendCategory),
            ),
            const SizedBox(height: 12),
            _field(
              _days,
              'Days until next renewal',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SaveAsTemplateToggle(
              value: _alsoTemplate,
              onChanged: (v) => setState(() => _alsoTemplate = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                foregroundColor: AppColors.zinc950,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, color: AppColors.zinc100),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.zinc600),
        filled: true,
        fillColor: AppColors.zinc900,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.zinc800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan500),
        ),
      ),
    );
  }

  Widget _typeButton(String value, String label) {
    final active = _type == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.cyan500 : AppColors.zinc900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.cyan500 : AppColors.zinc800,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.zinc950 : AppColors.zinc400,
            ),
          ),
        ),
      ),
    );
  }
}
