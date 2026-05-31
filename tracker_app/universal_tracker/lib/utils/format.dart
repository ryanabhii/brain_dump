import 'package:intl/intl.dart';

/// Whole days from now until [iso] (rounded up), matching the prototype's
/// `daysUntil` (Prototype.tsx line 116). Negative if the date has passed.
int daysUntil(String iso) {
  final ms = DateTime.parse(iso).difference(DateTime.now()).inMilliseconds;
  return (ms / 86400000).ceil();
}

/// Whole days since [iso] until now (floored). Null if [iso] is null.
int? daysSince(String? iso) {
  if (iso == null) return null;
  final ms = DateTime.now().difference(DateTime.parse(iso)).inMilliseconds;
  return (ms / 86400000).floor();
}

final _money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _money0 = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

/// "$1,234.56"
String money(num v) => _money.format(v);

/// "$1,235" (no cents)
String money0(num v) => _money0.format(v);
