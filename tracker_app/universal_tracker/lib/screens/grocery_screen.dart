import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/suggestions.dart';
import '../models/grocery.dart';
import '../models/templates.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/grouping.dart';
import '../widgets/save_as_template_toggle.dart';
import '../widgets/template_picker.dart';
import '../widgets/ui.dart';

/// Port of the React `GroceryScreen` (Prototype.tsx line 2022): a shared
/// shopping list (grouped by category, with member assignment + weekly
/// recurring) and a pantry view with low-stock alerts.
class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  String _view = 'list'; // 'list' | 'pantry'

  Color _memberColor(String m) => switch (m) {
    'You' => AppColors.cyan400,
    'Sam' => AppColors.emerald400,
    'Alex' => AppColors.amber400,
    _ => AppColors.zinc400,
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final g = app.data!.groceries;
    final pending = g.list.where((it) => !it.completed).toList();
    final done = g.list.where((it) => it.completed).toList();
    final lowStock = g.pantry.where((p) => p.isLow).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Household',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared with ${g.members.length} people',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.zinc500,
                      ),
                    ),
                  ],
                ),
              ),
              RoundIconButton(icon: Icons.add, onTap: () => _openAdd(context)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _segmented(pending.length, lowStock),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _membersRow(g.members),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _view == 'list'
              ? _listView(app, pending, done)
              : _pantryView(app, g.pantry, g.list),
        ),
      ],
    );
  }

  // ── Tabs ──────────────────────────────────────────────────
  Widget _segmented(int pendingCount, int lowCount) {
    Widget tab(String id, String label, int count, bool alert) {
      final active = _view == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _view = id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.zinc100 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active ? AppColors.zinc900 : AppColors.zinc400,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.zinc900
                          : alert
                          ? AppColors.a(AppColors.amber500, 0.3)
                          : AppColors.zinc800,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: active
                            ? AppColors.zinc100
                            : alert
                            ? AppColors.amber400
                            : AppColors.zinc400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.zinc900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.zinc800),
      ),
      child: Row(
        children: [
          tab('list', 'Groceries', pendingCount, false),
          tab('pantry', 'Pantry', lowCount, true),
        ],
      ),
    );
  }

  Widget _membersRow(List<String> members) {
    return Row(
      children: [
        const SectionLabel('Household:'),
        const SizedBox(width: 8),
        for (final m in members)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.a(_memberColor(m), 0.25),
              child: Text(
                m[0],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _memberColor(m),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── List view ─────────────────────────────────────────────
  Widget _listView(
    AppState app,
    List<GroceryItem> pending,
    List<GroceryItem> done,
  ) {
    // Group pending items by category (case-insensitive, sorted alphabetically).
    final byCat = groupByCaseInsensitive<GroceryItem>(
      pending,
      (it) => it.category,
    );
    final cats = byCat.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'List is empty 🎉',
                style: TextStyle(color: AppColors.zinc500),
              ),
            ),
          ),
        for (final cat in cats) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: SectionLabel(cat),
          ),
          for (final it in byCat[cat]!) ...[
            _GroceryRow(item: it, color: _memberColor(it.addedBy)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (done.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('In cart'),
              GestureDetector(
                onTap: app.clearCompletedGroceries,
                child: const Text(
                  'Clear',
                  style: TextStyle(fontSize: 11, color: AppColors.cyan400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final it in done)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => app.toggleGroceryItem(it.id),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.emerald500,
                        child: Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        it.name,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.zinc400,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => app.removeGroceryItem(it.id),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.zinc600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  // ── Pantry view ───────────────────────────────────────────
  Widget _pantryView(
    AppState app,
    List<PantryItem> pantry,
    List<GroceryItem> list,
  ) {
    final sorted = [...pantry]..sort((a, b) => a.qty.compareTo(b.qty));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        for (final p in sorted) ...[
          _PantryRow(
            item: p,
            onList: list.any(
              (g) =>
                  !g.completed && g.name.toLowerCase() == p.name.toLowerCase(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _view == 'list' ? const _GroceryAddSheet() : const _PantryAddSheet(),
    );
  }
}

// ── A single shopping-list row ─────────────────────────────────
class _GroceryRow extends StatelessWidget {
  final GroceryItem item;
  final Color color;
  const _GroceryRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: surfaceCard(radius: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => app.toggleGroceryItem(item.id),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.zinc600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.recurring == 'weekly') ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.repeat,
                        size: 12,
                        color: AppColors.violet400,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '×${item.qty}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.zinc500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => app.cycleMember(item.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.a(color, 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.addedBy,
                          style: TextStyle(fontSize: 10, color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => app.toggleRecurring(item.id),
                      child: Icon(
                        Icons.repeat,
                        size: 12,
                        color: item.recurring == 'weekly'
                            ? AppColors.violet400
                            : AppColors.zinc600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => app.removeGroceryItem(item.id),
            child: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.zinc600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── A single pantry row ────────────────────────────────────────
class _PantryRow extends StatelessWidget {
  final PantryItem item;
  final bool onList;
  const _PantryRow({required this.item, required this.onList});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final low = item.isLow;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: surfaceCard(
        radius: 12,
        fill: low ? AppColors.a(AppColors.amber500, 0.05) : null,
        ring: low ? AppColors.a(AppColors.amber500, 0.2) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (low) ...[
                      const SizedBox(width: 6),
                      Pill(
                        item.qty == 0 ? 'OUT' : 'LOW',
                        fg: AppColors.amber400,
                        bg: AppColors.a(AppColors.amber500, 0.2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.qty} ${item.unit} · alert at ${item.lowThreshold}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.zinc500,
                  ),
                ),
              ],
            ),
          ),
          if (low)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onList
                    ? null
                    : () {
                        final added = app.addPantryToList(item);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? '${item.name} added to list'
                                    : 'Already on list',
                              ),
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onList
                        ? AppColors.zinc800
                        : AppColors.a(AppColors.emerald500, 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    onList ? 'on list' : 'add',
                    style: TextStyle(
                      fontSize: 10,
                      color: onList ? AppColors.zinc500 : AppColors.emerald400,
                    ),
                  ),
                ),
              ),
            ),
          _StepButton(
            icon: Icons.remove,
            onTap: () => app.adjustPantry(item.id, -1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '${item.qty}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onTap: () => app.adjustPantry(item.id, 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: AppColors.zinc300),
    ),
  );
}

// ── Add sheets ─────────────────────────────────────────────────
class _GroceryAddSheet extends StatefulWidget {
  const _GroceryAddSheet();
  @override
  State<_GroceryAddSheet> createState() => _GroceryAddSheetState();
}

class _GroceryAddSheetState extends State<_GroceryAddSheet> {
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _category = TextEditingController();
  bool _recurring = false;
  bool _alsoTemplate = false;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _category.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final cat = _category.text;
    app.addGroceryItem(
      name: name,
      qty: qty,
      category: cat,
      recurring: _recurring,
    );
    if (_alsoTemplate) {
      app.saveGroceryTemplate(
        GroceryTemplate(
          id: app.newTemplateId('gt'),
          name: name,
          category: cat.trim().isEmpty ? 'Other' : cat.trim(),
          defaultQty: qty,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _alsoTemplate ? 'Added · template saved' : 'Added to list',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _applyTemplate(GroceryTemplate t) {
    setState(() {
      _name.text = t.name;
      _category.text = t.category;
      _qty.text = t.defaultQty.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SheetShell(
      title: 'Add to list',
      children: [
        TemplatePicker<GroceryTemplate>(
          templates: app.data!.groceryTemplates,
          accent: AppColors.emerald400,
          labelOf: (t) => t.name,
          subtitleOf: (t) => '${t.category} · ×${t.defaultQty}',
          iconOf: (_) => Icons.shopping_basket,
          onPick: _applyTemplate,
        ),
        AppAutocompleteField(
          controller: _name,
          hint: 'Item (e.g. Milk)',
          options: app.suggestionsFor(SuggestionField.grocery),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _qty,
                hint: 'Qty',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppAutocompleteField(
                controller: _category,
                hint: 'Category',
                options:
                    app.suggestionsFor(SuggestionField.groceryCategory),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _recurring = !_recurring),
          child: Row(
            children: [
              Icon(
                _recurring ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: _recurring ? AppColors.violet400 : AppColors.zinc600,
              ),
              const SizedBox(width: 8),
              const Text(
                'Re-add weekly',
                style: TextStyle(fontSize: 13, color: AppColors.zinc300),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SaveAsTemplateToggle(
          value: _alsoTemplate,
          onChanged: (v) => setState(() => _alsoTemplate = v),
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}

class _PantryAddSheet extends StatefulWidget {
  const _PantryAddSheet();
  @override
  State<_PantryAddSheet> createState() => _PantryAddSheetState();
}

class _PantryAddSheetState extends State<_PantryAddSheet> {
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _unit = TextEditingController();
  final _threshold = TextEditingController(text: '1');
  bool _alsoTemplate = false;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final qty = int.tryParse(_qty.text.trim()) ?? 1;
    final low = int.tryParse(_threshold.text.trim()) ?? 1;
    final unit = _unit.text;
    app.addPantryItem(name: name, qty: qty, lowThreshold: low, unit: unit);
    if (_alsoTemplate) {
      app.savePantryTemplate(
        PantryTemplate(
          id: app.newTemplateId('pt'),
          name: name,
          unit: unit.trim().isEmpty ? 'unit' : unit.trim(),
          lowThreshold: low,
          defaultStartQty: qty,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _alsoTemplate ? 'Pantry updated · template saved' : 'Pantry updated',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _applyTemplate(PantryTemplate t) {
    setState(() {
      _name.text = t.name;
      _unit.text = t.unit;
      _qty.text = t.defaultStartQty.toString();
      _threshold.text = t.lowThreshold.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SheetShell(
      title: 'Add to pantry',
      children: [
        TemplatePicker<PantryTemplate>(
          templates: app.data!.pantryTemplates,
          accent: AppColors.amber400,
          labelOf: (t) => t.name,
          subtitleOf: (t) => '${t.unit} · low ≤ ${t.lowThreshold}',
          iconOf: (_) => Icons.inventory_2,
          onPick: _applyTemplate,
        ),
        AppAutocompleteField(
          controller: _name,
          hint: 'Pantry item',
          options: app.suggestionsFor(SuggestionField.grocery),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _qty,
                hint: 'Qty',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppAutocompleteField(
                controller: _unit,
                hint: 'Unit (bottle, kg…)',
                options: app.suggestionsFor(SuggestionField.unit),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _threshold,
          hint: 'Alert when at or below',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        SaveAsTemplateToggle(
          value: _alsoTemplate,
          onChanged: (v) => setState(() => _alsoTemplate = v),
        ),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}
