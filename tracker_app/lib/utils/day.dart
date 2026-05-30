/// A stable `yyyy-mm-dd` key for a date, used for day grouping, streak
/// counting, and daily-reset logic. Local time.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Length of the consecutive-day streak ending today — or yesterday, if today
/// has no activity yet (so the streak isn't "broken" mid-day). Returns 0 when
/// neither today nor yesterday is in [activeDays] (a set of [dayKey]s).
int streakLength(Set<String> activeDays, DateTime now) {
  var cursor = DateTime(now.year, now.month, now.day);
  if (!activeDays.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!activeDays.contains(dayKey(cursor))) return 0;
  }
  var streak = 0;
  while (activeDays.contains(dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
