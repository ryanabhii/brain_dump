// Time helpers for killzones — ports of the prototype's `nowMin`, `fmtTime`,
// `timeUntil`, `startOfWeek`, `startOfMonth` (Prototype.tsx lines 98–147).

/// Minutes since local midnight for [d] (defaults to now).
int nowMin([DateTime? d]) {
  d ??= DateTime.now();
  return d.hour * 60 + d.minute;
}

/// "8:30 AM" from minutes-since-midnight.
String fmtTime(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  final ampm = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $ampm';
}

/// Time from now until [targetMin] today (wraps past midnight).
({int h, int m, int total}) timeUntil(int targetMin, [DateTime? now]) {
  final cur = nowMin(now);
  var diff = targetMin - cur;
  if (diff < 0) diff += 1440;
  return (h: diff ~/ 60, m: diff % 60, total: diff);
}

/// Midnight on Monday of the current week.
DateTime startOfWeek([DateTime? d]) {
  d ??= DateTime.now();
  final dayFromMonday = (d.weekday + 6) % 7; // Dart: Mon=1..Sun=7 → 0..6
  return DateTime(
    d.year,
    d.month,
    d.day,
  ).subtract(Duration(days: dayFromMonday));
}

/// Midnight on the first of the current month.
DateTime startOfMonth([DateTime? d]) {
  d ??= DateTime.now();
  return DateTime(d.year, d.month, 1);
}
