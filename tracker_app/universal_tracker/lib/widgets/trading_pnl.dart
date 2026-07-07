// Hide Flutter's rarely-used `Flow` layout widget so our model `Flow` wins.
import 'package:flutter/material.dart' hide Flow;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/suggestions.dart';
import '../models/templates.dart';
import '../models/trading.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/format.dart';
import '../utils/time_util.dart';
import 'save_as_template_toggle.dart';
import 'template_picker.dart';
import 'ui.dart';

/// Per-account P&L = current balance − lifetime net deposits. (Honest port of
/// the prototype's `computePnL`, Prototype.tsx line 151: without historical
/// balances we can only compute all-time P&L; the window affects the
/// deposit/withdrawal summary and the flows shown.)
class _PnL {
  final num pnl;
  final num netDeposits;
  final num windowDeposits;
  final num windowWithdrawals;
  const _PnL(
    this.pnl,
    this.netDeposits,
    this.windowDeposits,
    this.windowWithdrawals,
  );
}

_PnL _computePnL(TradingAccount acc, List<Flow> flows, DateTime? from) {
  final accFlows = flows.where((f) => f.accountId == acc.id);
  num net(Iterable<Flow> fs) => fs.fold<num>(
    0,
    (s, f) => s + (f.type == 'deposit' ? f.amount : -f.amount),
  );
  num sumOf(Iterable<Flow> fs, String type) =>
      fs.where((f) => f.type == type).fold<num>(0, (s, f) => s + f.amount);

  final lifetimeNet = net(accFlows);
  final window = from == null
      ? accFlows
      : accFlows.where((f) => !DateTime.parse(f.date).isBefore(from));
  return _PnL(
    acc.balance - lifetimeNet,
    lifetimeNet,
    sumOf(window, 'deposit'),
    sumOf(window, 'withdrawal'),
  );
}

String _signed(num v) => '${v >= 0 ? '+' : '−'}${money0(v.abs())}';

class TradingPnlSection extends StatefulWidget {
  const TradingPnlSection({super.key});

  @override
  State<TradingPnlSection> createState() => _TradingPnlSectionState();
}

class _TradingPnlSectionState extends State<TradingPnlSection> {
  String _window = 'month'; // week | month | all

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final trading = app.data!.trading;
    final from = switch (_window) {
      'week' => startOfWeek(),
      'month' => startOfMonth(),
      _ => null,
    };

    final stats = {
      for (final a in trading.accounts)
        a.id: _computePnL(a, trading.flows, from),
    };
    final totalBalance = trading.accounts.fold<num>(0, (s, a) => s + a.balance);
    final totalPnl = stats.values.fold<num>(0, (s, p) => s + p.pnl);
    final totalDep = stats.values.fold<num>(0, (s, p) => s + p.windowDeposits);
    final totalWd = stats.values.fold<num>(
      0,
      (s, p) => s + p.windowWithdrawals,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              children: const [
                Icon(Icons.attach_money, size: 12, color: AppColors.zinc400),
                SectionLabel('P&L'),
              ],
            ),
            const Spacer(),
            _miniButton('+ Account', () => _openAddAccount(context)),
            const SizedBox(width: 6),
            _miniButton('+ Flow', () => _openAddFlow(context), accent: true),
          ],
        ),
        const SizedBox(height: 12),

        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.a(AppColors.emerald500, 0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.a(AppColors.emerald500, 0.15),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final w in const [
                    ('week', 'This week'),
                    ('month', 'This month'),
                    ('all', 'All time'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _windowChip(w.$1, w.$2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Total balance'),
                        Text(
                          money0(totalBalance),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('All-time P&L'),
                        Text(
                          _signed(totalPnl),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: totalPnl >= 0
                                ? AppColors.emerald400
                                : AppColors.rose400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_window != 'all') ...[
                const Divider(height: 20, color: AppColors.zinc800),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_circle_down,
                      size: 12,
                      color: AppColors.emerald400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Deposited ${money0(totalDep)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.zinc300,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_circle_up,
                      size: 12,
                      color: AppColors.rose400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Withdrew ${money0(totalWd)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.zinc300,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        if (trading.accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No accounts yet. Tap "+ Account".',
                style: TextStyle(fontSize: 12, color: AppColors.zinc500),
              ),
            ),
          ),
        for (final a in trading.accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AccountTile(account: a, stats: stats[a.id]!, from: from),
          ),

        const SizedBox(height: 4),
        const Text(
          'P&L = current balance − net deposits. Update balances after each '
          'session to track gains/losses per account.',
          style: TextStyle(fontSize: 10, color: AppColors.zinc600, height: 1.4),
        ),
      ],
    );
  }

  Widget _windowChip(String id, String label) {
    final active = _window == id;
    return GestureDetector(
      onTap: () => setState(() => _window = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.a(AppColors.emerald500, 0.3)
              : AppColors.zinc900,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? AppColors.a(AppColors.emerald500, 0.4)
                : AppColors.zinc800,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? AppColors.emerald400 : AppColors.zinc400,
          ),
        ),
      ),
    );
  }

  Widget _miniButton(String label, VoidCallback onTap, {bool accent = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.a(AppColors.cyan500, 0.1)
              : AppColors.zinc900,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: accent
                ? AppColors.a(AppColors.cyan500, 0.3)
                : AppColors.zinc800,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: accent ? AppColors.cyan300 : AppColors.zinc400,
          ),
        ),
      ),
    );
  }

  void _openAddAccount(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AccountAddSheet(),
  );

  void _openAddFlow(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _FlowAddSheet(),
  );
}

class _AccountTile extends StatefulWidget {
  final TradingAccount account;
  final _PnL stats;
  final DateTime? from;
  const _AccountTile({
    required this.account,
    required this.stats,
    required this.from,
  });

  @override
  State<_AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<_AccountTile> {
  bool _expanded = false;
  late final TextEditingController _balance = TextEditingController(
    text: widget.account.balance.round().toString(),
  );

  @override
  void dispose() {
    _balance.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(AppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.zinc900,
        title: const Text('Remove account?'),
        content: const Text('This removes the account and all its flows.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.rose400),
            ),
          ),
        ],
      ),
    );
    if (ok == true) app.removeAccount(widget.account.id);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final a = widget.account;
    final pos = widget.stats.pnl >= 0;
    final flows =
        app.data!.trading.flows
            .where((f) => f.accountId == a.id)
            .where(
              (f) =>
                  widget.from == null ||
                  !DateTime.parse(f.date).isBefore(widget.from!),
            )
            .toList()
          ..sort((x, y) => y.date.compareTo(x.date));

    return Container(
      decoration: surfaceCard(radius: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                                a.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Pill(
                              a.type,
                              fg: AppColors.zinc400,
                              bg: AppColors.zinc800,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Balance ${money0(a.balance)} · Net in ${money0(widget.stats.netDeposits)}',
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
                        _signed(widget.stats.pnl),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: pos ? AppColors.emerald400 : AppColors.rose400,
                        ),
                      ),
                      const Text(
                        'all-time P&L',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.zinc500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.zinc800),
                  Row(
                    children: [
                      const SectionLabel('Update balance'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _balance,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.zinc100,
                            ),
                            onSubmitted: (v) {
                              final n = num.tryParse(v.trim());
                              if (n != null) app.updateAccountBalance(a.id, n);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: AppColors.zinc900,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.zinc800,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.cyan500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _confirmRemove(app),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.zinc600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (flows.isEmpty)
                    const Text(
                      'No flows in this window.',
                      style: TextStyle(fontSize: 11, color: AppColors.zinc600),
                    )
                  else
                    for (final f in flows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              f.type == 'deposit'
                                  ? Icons.arrow_circle_down
                                  : Icons.arrow_circle_up,
                              size: 14,
                              color: f.type == 'deposit'
                                  ? AppColors.emerald400
                                  : AppColors.rose400,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                f.note.isEmpty
                                    ? (f.type == 'deposit'
                                          ? 'Deposit'
                                          : 'Withdrawal')
                                    : f.note,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.zinc300,
                                ),
                              ),
                            ),
                            Text(
                              '${f.type == 'deposit' ? '+' : '−'}${money0(f.amount)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: f.type == 'deposit'
                                    ? AppColors.emerald400
                                    : AppColors.rose400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'MMM d',
                              ).format(DateTime.parse(f.date)),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.zinc500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => app.removeFlow(f.id),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: AppColors.zinc600,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sheets ─────────────────────────────────────────────────────
class _AccountAddSheet extends StatefulWidget {
  const _AccountAddSheet();
  @override
  State<_AccountAddSheet> createState() => _AccountAddSheetState();
}

class _AccountAddSheetState extends State<_AccountAddSheet> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  // Seeded from the user's default currency in [initState] so each new
  // account picks up their preference instead of always defaulting to USD.
  final _currency = TextEditingController();
  String _type = 'broker';

  @override
  void initState() {
    super.initState();
    _currency.text = context.read<AppState>().data!.profile.defaultCurrency;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final bal = double.tryParse(_balance.text.trim());
    if (name.isEmpty || bal == null) return;
    final messenger = ScaffoldMessenger.of(context);
    context.read<AppState>().addAccount(
      name: name,
      type: _type,
      currency: _currency.text,
      balance: bal,
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Account added'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'New account',
      children: [
        AppAutocompleteField(
          controller: _name,
          hint: 'Account name (e.g. FTMO, Kraken)',
          options: context.read<AppState>().suggestionsFor(
            SuggestionField.broker,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final t in const ['broker', 'wallet', 'prop'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == t
                            ? AppColors.cyan500
                            : AppColors.zinc900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == t
                              ? AppColors.cyan500
                              : AppColors.zinc800,
                        ),
                      ),
                      child: Text(
                        t,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _type == t
                              ? AppColors.zinc950
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
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: _balance,
                hint: 'Current balance',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppAutocompleteField(
                controller: _currency,
                hint: 'USD',
                options: context.read<AppState>().suggestionsFor(
                  SuggestionField.currency,
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

class _FlowAddSheet extends StatefulWidget {
  const _FlowAddSheet();
  @override
  State<_FlowAddSheet> createState() => _FlowAddSheetState();
}

class _FlowAddSheetState extends State<_FlowAddSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _accountId;
  String _type = 'deposit';
  DateTime _date = DateTime.now();
  bool _alsoTemplate = false;
  final _templateName = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _templateName.dispose();
    super.dispose();
  }

  void _save() {
    final amt = double.tryParse(_amount.text.trim());
    if (_accountId == null || amt == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final note = _note.text.trim();
    app.addFlow(
      accountId: _accountId!,
      type: _type,
      amount: amt,
      date: _date.toIso8601String(),
      note: note,
    );
    if (_alsoTemplate) {
      // Flows need a human-readable name (separate from the per-entry note),
      // so the template's name comes from a dedicated field that appears
      // once the toggle is on. Falls back to "{type} ${amt}" so a forgotten
      // name still produces a usable template.
      final name = _templateName.text.trim().isEmpty
          ? '${_type == 'deposit' ? 'Deposit' : 'Withdrawal'} '
                '\$${amt.toStringAsFixed(2)}'
          : _templateName.text.trim();
      app.saveFlowTemplate(
        FlowTemplate(
          id: app.newTemplateId('ft'),
          name: name,
          type: _type,
          amount: amt,
          note: note,
        ),
      );
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _alsoTemplate
              ? '${_type == 'deposit' ? 'Deposit' : 'Withdrawal'} logged · template saved'
              : _type == 'deposit'
              ? 'Deposit logged'
              : 'Withdrawal logged',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _applyTemplate(FlowTemplate t) {
    setState(() {
      _type = t.type;
      if (t.amount > 0) _amount.text = t.amount.toString();
      if (t.note.isNotEmpty) _note.text = t.note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final accounts = app.data!.trading.accounts;
    return SheetShell(
      title: 'Deposit / Withdrawal',
      children: [
        TemplatePicker<FlowTemplate>(
          templates: app.data!.flowTemplates,
          accent: AppColors.orange400,
          labelOf: (t) => t.name,
          subtitleOf: (t) =>
              '${t.type == 'deposit' ? '+' : '−'}\$${t.amount.toStringAsFixed(2)}',
          iconOf: (t) =>
              t.type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
          onPick: _applyTemplate,
        ),
        const SectionLabel('Account'),
        const SizedBox(height: 8),
        if (accounts.isEmpty)
          const Text(
            'No accounts yet — add one first.',
            style: TextStyle(fontSize: 12, color: AppColors.zinc500),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in accounts)
                GestureDetector(
                  onTap: () => setState(() => _accountId = a.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _accountId == a.id
                          ? AppColors.cyan500
                          : AppColors.zinc900,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _accountId == a.id
                            ? AppColors.cyan500
                            : AppColors.zinc800,
                      ),
                    ),
                    child: Text(
                      a.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: _accountId == a.id
                            ? AppColors.zinc950
                            : AppColors.zinc400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final t in const ['deposit', 'withdrawal'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _type == t
                            ? (t == 'deposit'
                                  ? AppColors.emerald500
                                  : AppColors.rose500)
                            : AppColors.zinc900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _type == t
                              ? Colors.transparent
                              : AppColors.zinc800,
                        ),
                      ),
                      child: Text(
                        t == 'deposit' ? 'Deposit' : 'Withdrawal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _type == t ? Colors.white : AppColors.zinc400,
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
          controller: _amount,
          hint: 'Amount',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.zinc900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.zinc800),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.zinc500,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(_date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.zinc100,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppTextField(controller: _note, hint: 'Note (optional)'),
        const SizedBox(height: 12),
        SaveAsTemplateToggle(
          value: _alsoTemplate,
          onChanged: (v) => setState(() => _alsoTemplate = v),
        ),
        if (_alsoTemplate) ...[
          const SizedBox(height: 8),
          AppTextField(
            controller: _templateName,
            hint: 'Template name (e.g. Monthly DCA)',
          ),
        ],
        const SizedBox(height: 12),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}
