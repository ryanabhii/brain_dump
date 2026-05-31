import '../models/app_data.dart';
import '../models/body.dart';
import '../models/brain_dump.dart';
import '../models/grocery.dart';
import '../models/killzone.dart';
import '../models/subscription.dart';
import '../models/trading.dart';
import '../models/workout.dart';
import 'merge.dart';

/// A shareable unit of the app. Each tab owns one or more named *collections*
/// (lists of id'd items) that sync independently. [extract] pulls them out of
/// [AppData] as plain JSON; [apply] writes a merged set back into a new
/// [AppData]. Scalar/per-user settings (macro goals, notification prefs, etc.)
/// are deliberately NOT synced — only the collaborative lists are.
class SyncTab {
  final String key; // stable storage/sharing key (also the Drive file name)
  final String label; // shown in the share UI
  final Map<String, List<Json>> Function(AppData) extract;
  final AppData Function(AppData, Map<String, List<Json>>) apply;

  const SyncTab(this.key, this.label, this.extract, this.apply);
}

List<Json> _json(Iterable items) =>
    items.map((e) => (e as dynamic).toJson() as Json).toList();

/// The shareable tabs. Keep [key]s stable — they name the synced files.
const List<SyncTab> kSyncTabs = [
  SyncTab('killzones', 'Killzones', _extractKillzones, _applyKillzones),
  SyncTab('spend', 'Spend', _extractSpend, _applySpend),
  SyncTab('capture', 'Capture', _extractCapture, _applyCapture),
  SyncTab('household', 'Household', _extractHousehold, _applyHousehold),
  SyncTab('body', 'Body', _extractBody, _applyBody),
  SyncTab('trading', 'Trading', _extractTrading, _applyTrading),
];

SyncTab? syncTabByKey(String key) {
  for (final t in kSyncTabs) {
    if (t.key == key) return t;
  }
  return null;
}

String syncTabLabel(String key) => syncTabByKey(key)?.label ?? key;

// ── Killzones ──
Map<String, List<Json>> _extractKillzones(AppData d) => {
  'killzones': _json(d.killzones),
};
AppData _applyKillzones(AppData d, Map<String, List<Json>> m) => d.copyWith(
  killzones: (m['killzones'] ?? const []).map(Killzone.fromJson).toList(),
);

// ── Spend (subscriptions) ──
Map<String, List<Json>> _extractSpend(AppData d) => {
  'subscriptions': _json(d.subscriptions),
};
AppData _applySpend(AppData d, Map<String, List<Json>> m) => d.copyWith(
  subscriptions: (m['subscriptions'] ?? const [])
      .map(Subscription.fromJson)
      .toList(),
);

// ── Capture (brain dumps) ──
Map<String, List<Json>> _extractCapture(AppData d) => {
  'braindumps': _json(d.braindumps),
};
AppData _applyCapture(AppData d, Map<String, List<Json>> m) => d.copyWith(
  braindumps: (m['braindumps'] ?? const []).map(BrainDump.fromJson).toList(),
);

// ── Household (shopping list + pantry) ──
Map<String, List<Json>> _extractHousehold(AppData d) => {
  'list': _json(d.groceries.list),
  'pantry': _json(d.groceries.pantry),
};
AppData _applyHousehold(AppData d, Map<String, List<Json>> m) => d.copyWith(
  groceries: d.groceries.copyWith(
    list: (m['list'] ?? const []).map(GroceryItem.fromJson).toList(),
    pantry: (m['pantry'] ?? const []).map(PantryItem.fromJson).toList(),
  ),
);

// ── Body (meals + workouts; macro goals/streak stay per-user) ──
Map<String, List<Json>> _extractBody(AppData d) => {
  'meals': _json(d.body.meals),
  'workouts': _json(d.body.workouts),
};
AppData _applyBody(AppData d, Map<String, List<Json>> m) => d.copyWith(
  body: d.body.copyWith(
    meals: (m['meals'] ?? const []).map(Meal.fromJson).toList(),
    workouts: (m['workouts'] ?? const []).map(Workout.fromJson).toList(),
  ),
);

// ── Trading (accounts + flows) ──
Map<String, List<Json>> _extractTrading(AppData d) => {
  'accounts': _json(d.trading.accounts),
  'flows': _json(d.trading.flows),
};
AppData _applyTrading(AppData d, Map<String, List<Json>> m) => d.copyWith(
  trading: d.trading.copyWith(
    accounts: (m['accounts'] ?? const []).map(TradingAccount.fromJson).toList(),
    flows: (m['flows'] ?? const []).map(Flow.fromJson).toList(),
  ),
);
