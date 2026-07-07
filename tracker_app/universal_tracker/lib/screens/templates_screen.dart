import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart' show PhoneWidth;
import '../models/templates.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/time_util.dart';
import '../widgets/ui.dart';

/// Central place to view + edit every kind of template. Pushed from
/// Profile → Templates. One section per template type; each row shows the
/// preset summary, taps open the editor, swipe-left deletes.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TemplatesScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.data!;
    return PhoneWidth(
      child: Scaffold(
        backgroundColor: AppColors.zinc950,
        appBar: AppBar(
          backgroundColor: AppColors.zinc950,
          elevation: 0,
          title: const Text(
            'Templates',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Pre-saved entries you can re-use one tap from any add sheet. '
              'Edits here apply to future logs only.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.zinc500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            _TemplateSection<MealTemplate>(
              title: 'Meals',
              icon: Icons.restaurant,
              accent: AppColors.cyan500,
              items: data.mealTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) => _mealSummary(t),
              onAdd: () => _editMeal(context, null),
              onTap: (t) => _editMeal(context, t),
              onDelete: app.removeMealTemplate,
            ),
            _TemplateSection<WorkoutTemplate>(
              title: 'Workouts',
              icon: Icons.fitness_center,
              accent: AppColors.sky400,
              items: data.workoutTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) {
                final dur = t.defaultDurationMin > 0
                    ? '${t.defaultDurationMin.toStringAsFixed(0)} min'
                    : null;
                return [
                  t.focus,
                  dur,
                ].where((s) => s != null && s.isNotEmpty).join(' · ');
              },
              onAdd: () => _editWorkout(context, null),
              onTap: (t) => _editWorkout(context, t),
              onDelete: app.removeWorkoutTemplate,
            ),
            _TemplateSection<GroceryTemplate>(
              title: 'Groceries',
              icon: Icons.shopping_basket,
              accent: AppColors.emerald400,
              items: data.groceryTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) => '${t.category} · ×${t.defaultQty}',
              onAdd: () => _editGrocery(context, null),
              onTap: (t) => _editGrocery(context, t),
              onDelete: app.removeGroceryTemplate,
            ),
            _TemplateSection<PantryTemplate>(
              title: 'Pantry',
              icon: Icons.inventory_2,
              accent: AppColors.amber400,
              items: data.pantryTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) => '${t.unit} · low ≤ ${t.lowThreshold}',
              onAdd: () => _editPantry(context, null),
              onTap: (t) => _editPantry(context, t),
              onDelete: app.removePantryTemplate,
            ),
            _TemplateSection<SubscriptionTemplate>(
              title: 'Subscriptions',
              icon: Icons.credit_card,
              accent: AppColors.rose400,
              items: data.subscriptionTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) =>
                  '\$${t.cost.toStringAsFixed(2)} · every ${t.cadenceDays}d',
              onAdd: () => _editSubscription(context, null),
              onTap: (t) => _editSubscription(context, t),
              onDelete: app.removeSubscriptionTemplate,
            ),
            _TemplateSection<KillzoneTemplate>(
              title: 'Killzones',
              icon: Icons.trending_up,
              accent: AppColors.violet400,
              items: data.killzoneTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) =>
                  '${fmtTime(t.startMin)} – ${fmtTime(t.endMin)}',
              onAdd: () => _editKillzone(context, null),
              onTap: (t) => _editKillzone(context, t),
              onDelete: app.removeKillzoneTemplate,
            ),
            _TemplateSection<FlowTemplate>(
              title: 'Trading deposits & withdrawals',
              icon: Icons.swap_vert,
              accent: AppColors.orange400,
              items: data.flowTemplates,
              labelOf: (t) => t.name,
              subtitleOf: (t) =>
                  '${t.type == 'deposit' ? '+' : '−'}\$${t.amount.toStringAsFixed(2)}'
                  '${t.note.isEmpty ? '' : ' · ${t.note}'}',
              onAdd: () => _editFlow(context, null),
              onTap: (t) => _editFlow(context, t),
              onDelete: app.removeFlowTemplate,
            ),
          ],
        ),
      ),
    );
  }

  static String _mealSummary(MealTemplate t) {
    final parts = <String>[
      '${t.kcalPer100.toStringAsFixed(0)} kcal/100g',
      'P ${t.proteinPer100.toStringAsFixed(0)}g',
      'C ${t.carbsPer100.toStringAsFixed(0)}g',
      'F ${t.fatPer100.toStringAsFixed(0)}g',
    ];
    return parts.join(' · ');
  }

  // ── Editor entrypoints ─────────────────────────────────────────────────

  Future<void> _editMeal(BuildContext context, MealTemplate? t) =>
      _openEditorSheet(context, _MealTemplateEditor(template: t));

  Future<void> _editWorkout(BuildContext context, WorkoutTemplate? t) =>
      _openEditorSheet(context, _WorkoutTemplateEditor(template: t));

  Future<void> _editGrocery(BuildContext context, GroceryTemplate? t) =>
      _openEditorSheet(context, _GroceryTemplateEditor(template: t));

  Future<void> _editPantry(BuildContext context, PantryTemplate? t) =>
      _openEditorSheet(context, _PantryTemplateEditor(template: t));

  Future<void> _editSubscription(
    BuildContext context,
    SubscriptionTemplate? t,
  ) => _openEditorSheet(context, _SubscriptionTemplateEditor(template: t));

  Future<void> _editKillzone(BuildContext context, KillzoneTemplate? t) =>
      _openEditorSheet(context, _KillzoneTemplateEditor(template: t));

  Future<void> _editFlow(BuildContext context, FlowTemplate? t) =>
      _openEditorSheet(context, _FlowTemplateEditor(template: t));

  Future<void> _openEditorSheet(BuildContext context, Widget editor) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => editor,
    );
  }
}

// ─── Generic section ──────────────────────────────────────────────────────

class _TemplateSection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;
  final VoidCallback onAdd;
  final void Function(T) onTap;
  final void Function(String id) onDelete;

  const _TemplateSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.items,
    required this.labelOf,
    required this.onAdd,
    required this.onTap,
    required this.onDelete,
    this.subtitleOf,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.a(accent, 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add, size: 16, color: accent),
                label: Text(
                  'Add',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: surfaceCard(),
              child: Text(
                'No templates yet — tap Add to create one.',
                style: TextStyle(fontSize: 12, color: AppColors.zinc500),
              ),
            )
          else
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TemplateRow(
                  label: labelOf(t),
                  subtitle: subtitleOf?.call(t),
                  accent: accent,
                  onTap: () => onTap(t),
                  onDelete: () => onDelete((t as dynamic).id as String),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateRow({
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('tpl-row-$label-${identityHashCode(this)}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.a(AppColors.rose500, 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.rose400),
      ),
      confirmDismiss: (_) async {
        // Confirm via a tiny dialog so a slip doesn't lose work.
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.zinc950,
                title: const Text(
                  'Delete template?',
                  style: TextStyle(fontSize: 16),
                ),
                content: Text(
                  '"$label" will be removed. Logs already created from this '
                  'template keep their data.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.zinc400,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rose400,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: surfaceCard(),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 28,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
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
    );
  }
}

// ─── Editors ──────────────────────────────────────────────────────────────
// Each follows the same shape: SheetShell + fields + Save button. Editing
// reuses the existing template's id; creating mints a new one via AppState.

class _EditorShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  const _EditorShell({
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => SheetShell(
    title: title,
    children: [
      ...children,
      const SizedBox(height: 16),
      PrimaryButton(label: 'Save template', onPressed: onSave),
    ],
  );
}

final _decimal = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));
final _integer = FilteringTextInputFormatter.digitsOnly;

class _MealTemplateEditor extends StatefulWidget {
  final MealTemplate? template;
  const _MealTemplateEditor({this.template});
  @override
  State<_MealTemplateEditor> createState() => _MealTemplateEditorState();
}

class _MealTemplateEditorState extends State<_MealTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _serving;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _kcal = TextEditingController(text: _fmt(t?.kcalPer100 ?? 0));
    _protein = TextEditingController(text: _fmt(t?.proteinPer100 ?? 0));
    _carbs = TextEditingController(text: _fmt(t?.carbsPer100 ?? 0));
    _fat = TextEditingController(text: _fmt(t?.fatPer100 ?? 0));
    _serving = TextEditingController(text: _fmt(t?.defaultServingG ?? 100));
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _serving.dispose();
    super.dispose();
  }

  String _fmt(num v) => v == 0 ? '' : v.toString();

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    app.saveMealTemplate(
      MealTemplate(
        id: widget.template?.id ?? app.newTemplateId('mt'),
        name: name,
        kcalPer100: double.tryParse(_kcal.text) ?? 0,
        proteinPer100: double.tryParse(_protein.text) ?? 0,
        carbsPer100: double.tryParse(_carbs.text) ?? 0,
        fatPer100: double.tryParse(_fat.text) ?? 0,
        defaultServingG: double.tryParse(_serving.text) ?? 100,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null ? 'New meal template' : 'Edit meal',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Meal name'),
      const SizedBox(height: 12),
      const SectionLabel('Per 100g'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _numField(_kcal, 'kcal')),
          const SizedBox(width: 8),
          Expanded(child: _numField(_protein, 'Protein g')),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _numField(_carbs, 'Carbs g')),
          const SizedBox(width: 8),
          Expanded(child: _numField(_fat, 'Fat g')),
        ],
      ),
      const SizedBox(height: 12),
      const SectionLabel('Default serving (g)'),
      const SizedBox(height: 8),
      _numField(_serving, '100'),
    ],
  );
}

class _WorkoutTemplateEditor extends StatefulWidget {
  final WorkoutTemplate? template;
  const _WorkoutTemplateEditor({this.template});
  @override
  State<_WorkoutTemplateEditor> createState() => _WorkoutTemplateEditorState();
}

class _WorkoutTemplateEditorState extends State<_WorkoutTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _focus;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _focus = TextEditingController(text: t?.focus ?? '');
    _duration = TextEditingController(
      text: (t?.defaultDurationMin ?? 0) == 0
          ? ''
          : t!.defaultDurationMin.toString(),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    app.saveWorkoutTemplate(
      WorkoutTemplate(
        id: widget.template?.id ?? app.newTemplateId('wt'),
        name: name,
        focus: _focus.text.trim(),
        defaultDurationMin: double.tryParse(_duration.text) ?? 0,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null ? 'New workout template' : 'Edit workout',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Workout name'),
      const SizedBox(height: 8),
      AppTextField(controller: _focus, hint: 'Focus (optional)'),
      const SizedBox(height: 8),
      _numField(_duration, 'Default duration (min)'),
    ],
  );
}

class _GroceryTemplateEditor extends StatefulWidget {
  final GroceryTemplate? template;
  const _GroceryTemplateEditor({this.template});
  @override
  State<_GroceryTemplateEditor> createState() => _GroceryTemplateEditorState();
}

class _GroceryTemplateEditorState extends State<_GroceryTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _qty;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _category = TextEditingController(text: t?.category ?? 'Other');
    _qty = TextEditingController(text: (t?.defaultQty ?? 1).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    app.saveGroceryTemplate(
      GroceryTemplate(
        id: widget.template?.id ?? app.newTemplateId('gt'),
        name: name,
        category: _category.text.trim().isEmpty
            ? 'Other'
            : _category.text.trim(),
        defaultQty: int.tryParse(_qty.text) ?? 1,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null ? 'New grocery template' : 'Edit grocery',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Item name'),
      const SizedBox(height: 8),
      AppTextField(controller: _category, hint: 'Category (e.g. Dairy)'),
      const SizedBox(height: 8),
      _intField(_qty, 'Default qty'),
    ],
  );
}

class _PantryTemplateEditor extends StatefulWidget {
  final PantryTemplate? template;
  const _PantryTemplateEditor({this.template});
  @override
  State<_PantryTemplateEditor> createState() => _PantryTemplateEditorState();
}

class _PantryTemplateEditorState extends State<_PantryTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _low;
  late final TextEditingController _start;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _unit = TextEditingController(text: t?.unit ?? 'unit');
    _low = TextEditingController(text: (t?.lowThreshold ?? 1).toString());
    _start = TextEditingController(text: (t?.defaultStartQty ?? 1).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _low.dispose();
    _start.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    app.savePantryTemplate(
      PantryTemplate(
        id: widget.template?.id ?? app.newTemplateId('pt'),
        name: name,
        unit: _unit.text.trim().isEmpty ? 'unit' : _unit.text.trim(),
        lowThreshold: int.tryParse(_low.text) ?? 1,
        defaultStartQty: int.tryParse(_start.text) ?? 1,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null ? 'New pantry template' : 'Edit pantry',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Item name'),
      const SizedBox(height: 8),
      AppTextField(controller: _unit, hint: 'Unit (g, ml, unit, ...)'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _intField(_low, 'Low threshold')),
          const SizedBox(width: 8),
          Expanded(child: _intField(_start, 'Default start qty')),
        ],
      ),
    ],
  );
}

class _SubscriptionTemplateEditor extends StatefulWidget {
  final SubscriptionTemplate? template;
  const _SubscriptionTemplateEditor({this.template});
  @override
  State<_SubscriptionTemplateEditor> createState() =>
      _SubscriptionTemplateEditorState();
}

class _SubscriptionTemplateEditorState
    extends State<_SubscriptionTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _cost;
  late final TextEditingController _category;
  late final TextEditingController _cadence;
  late final TextEditingController _apiCap;
  String _type = 'subscription';

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _cost = TextEditingController(text: (t?.cost ?? 0).toString());
    _category = TextEditingController(text: t?.category ?? 'Other');
    _cadence = TextEditingController(text: (t?.cadenceDays ?? 30).toString());
    _apiCap = TextEditingController(
      text: (t?.apiCap ?? 0) == 0 ? '' : t!.apiCap.toString(),
    );
    _type = t?.type ?? 'subscription';
  }

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _category.dispose();
    _cadence.dispose();
    _apiCap.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    final cap = double.tryParse(_apiCap.text);
    app.saveSubscriptionTemplate(
      SubscriptionTemplate(
        id: widget.template?.id ?? app.newTemplateId('st'),
        name: name,
        cost: double.tryParse(_cost.text) ?? 0,
        type: _type,
        category: _category.text.trim().isEmpty
            ? 'Other'
            : _category.text.trim(),
        cadenceDays: int.tryParse(_cadence.text) ?? 30,
        apiCap: (_type == 'api' && cap != null && cap > 0) ? cap : null,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null
        ? 'New subscription template'
        : 'Edit subscription',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Name (e.g. Spotify)'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _numField(_cost, 'Cost')),
          const SizedBox(width: 8),
          Expanded(child: _intField(_cadence, 'Every N days')),
        ],
      ),
      const SizedBox(height: 8),
      AppTextField(controller: _category, hint: 'Category'),
      const SizedBox(height: 12),
      const SectionLabel('Type'),
      const SizedBox(height: 6),
      Row(
        children: [
          _segChip(
            'Subscription',
            _type == 'subscription',
            () => setState(() => _type = 'subscription'),
          ),
          const SizedBox(width: 8),
          _segChip('API', _type == 'api', () => setState(() => _type = 'api')),
        ],
      ),
      if (_type == 'api') ...[
        const SizedBox(height: 8),
        _numField(_apiCap, 'API cap (e.g. monthly \$ limit)'),
      ],
    ],
  );
}

class _KillzoneTemplateEditor extends StatefulWidget {
  final KillzoneTemplate? template;
  const _KillzoneTemplateEditor({this.template});
  @override
  State<_KillzoneTemplateEditor> createState() =>
      _KillzoneTemplateEditorState();
}

class _KillzoneTemplateEditorState extends State<_KillzoneTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _checklist;
  int _start = 9 * 60;
  int _end = 11 * 60;
  String _color = 'amber';

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _checklist = TextEditingController(text: t?.checklist.join('\n') ?? '');
    if (t != null) {
      _start = t.startMin;
      _end = t.endMin;
      _color = t.color;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _checklist.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final cur = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
    );
    if (picked == null) return;
    setState(() {
      final m = picked.hour * 60 + picked.minute;
      if (start) {
        _start = m;
      } else {
        _end = m;
      }
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    final list = _checklist.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    app.saveKillzoneTemplate(
      KillzoneTemplate(
        id: widget.template?.id ?? app.newTemplateId('kt'),
        name: name,
        startMin: _start,
        endMin: _end,
        color: _color,
        checklist: list,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null ? 'New killzone template' : 'Edit killzone',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Name (e.g. London)'),
      const SizedBox(height: 12),
      const SectionLabel('Window'),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: _timeBtn(fmtTime(_start), () => _pickTime(true))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('to', style: TextStyle(color: AppColors.zinc500)),
          ),
          Expanded(child: _timeBtn(fmtTime(_end), () => _pickTime(false))),
        ],
      ),
      const SizedBox(height: 12),
      const SectionLabel('Accent'),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in const ['amber', 'sky', 'rose', 'violet', 'emerald'])
            _colorDot(c, _color == c, () => setState(() => _color = c)),
        ],
      ),
      const SizedBox(height: 12),
      const SectionLabel('Checklist (one per line)'),
      const SizedBox(height: 6),
      AppTextField(
        controller: _checklist,
        hint: 'HTF bias set\nNews checked\nRisk defined',
        maxLines: 4,
      ),
    ],
  );
}

class _FlowTemplateEditor extends StatefulWidget {
  final FlowTemplate? template;
  const _FlowTemplateEditor({this.template});
  @override
  State<_FlowTemplateEditor> createState() => _FlowTemplateEditorState();
}

class _FlowTemplateEditorState extends State<_FlowTemplateEditor> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String _type = 'deposit';

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _amount = TextEditingController(
      text: (t?.amount ?? 0) == 0 ? '' : t!.amount.toString(),
    );
    _note = TextEditingController(text: t?.note ?? '');
    _type = t?.type ?? 'deposit';
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final app = context.read<AppState>();
    app.saveFlowTemplate(
      FlowTemplate(
        id: widget.template?.id ?? app.newTemplateId('ft'),
        name: name,
        type: _type,
        amount: double.tryParse(_amount.text) ?? 0,
        note: _note.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => _EditorShell(
    title: widget.template == null ? 'New flow template' : 'Edit flow',
    onSave: _save,
    children: [
      AppTextField(controller: _name, hint: 'Name (e.g. Monthly DCA)'),
      const SizedBox(height: 8),
      Row(
        children: [
          _segChip(
            'Deposit',
            _type == 'deposit',
            () => setState(() => _type = 'deposit'),
          ),
          const SizedBox(width: 8),
          _segChip(
            'Withdrawal',
            _type == 'withdrawal',
            () => setState(() => _type = 'withdrawal'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _numField(_amount, 'Amount'),
      const SizedBox(height: 8),
      AppTextField(controller: _note, hint: 'Note (optional)'),
    ],
  );
}

// ─── Shared atoms ──────────────────────────────────────────────────────────

Widget _numField(TextEditingController c, String hint) => TextField(
  controller: c,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [_decimal],
  style: const TextStyle(color: AppColors.zinc100, fontSize: 14),
  decoration: _denseInput(hint),
);

Widget _intField(TextEditingController c, String hint) => TextField(
  controller: c,
  keyboardType: TextInputType.number,
  inputFormatters: [_integer],
  style: const TextStyle(color: AppColors.zinc100, fontSize: 14),
  decoration: _denseInput(hint),
);

InputDecoration _denseInput(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.zinc600, fontSize: 13),
  filled: true,
  fillColor: AppColors.zinc900,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.zinc800),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.cyan500, width: 1.4),
  ),
);

Widget _segChip(String label, bool active, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.cyan500 : AppColors.zinc900,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.cyan500 : AppColors.zinc800,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.zinc950 : AppColors.zinc300,
          ),
        ),
      ),
    );

Widget _timeBtn(String label, VoidCallback onTap) => InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(10),
  child: Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.zinc900,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.zinc800),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.zinc100,
      ),
    ),
  ),
);

Widget _colorDot(String name, bool active, VoidCallback onTap) {
  final color = switch (name) {
    'amber' => AppColors.amber400,
    'sky' => AppColors.sky400,
    'rose' => AppColors.rose400,
    'violet' => AppColors.violet400,
    'emerald' => AppColors.emerald400,
    _ => AppColors.zinc500,
  };
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: active
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    ),
  );
}
