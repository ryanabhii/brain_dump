/// A logged workout. Mirrors [Meal]: it persists and drives the real "This
/// week" list. [date] is ISO-8601 (for day grouping); [time] is a display
/// string like "6:30 PM".
class Workout {
  final String id;
  final String name;
  final String focus; // e.g. "Chest · Shoulders · Triceps"
  final num durationMin;
  final String time;
  final String date;

  const Workout({
    required this.id,
    required this.name,
    this.focus = '',
    this.durationMin = 0,
    this.time = '',
    this.date = '',
  });

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
    id: j['id'] as String,
    name: j['name'] as String,
    focus: j['focus'] as String? ?? '',
    durationMin: (j['durationMin'] as num?) ?? 0,
    time: j['time'] as String? ?? '',
    date: j['date'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focus': focus,
    'durationMin': durationMin,
    'time': time,
    'date': date,
  };
}
