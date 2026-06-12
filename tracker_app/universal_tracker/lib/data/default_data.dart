/// Returns an ISO-8601 timestamp [d] days from now (fractional days allowed).
/// Direct port of the prototype's `todayPlus` helper (Prototype.tsx line 24).
String todayPlus(num d) => DateTime.now()
    .add(Duration(milliseconds: (d * 86400000).round()))
    .toIso8601String();

/// Seed data used on first launch.
///
/// Shipped lean: only the killzone session presets (which are real ICT trading
/// sessions, useful as a starting point) and sensible default macro goals.
/// Everything else (subscriptions, trading, capture, household, body log) is
/// empty so a brand-new user sees their own data, not someone else's demo.
Map<String, dynamic> buildDefaultData() => {
  'killzones': [
    {
      'id': 'kz1',
      'name': 'Asian',
      'startMin': 19 * 60,
      'endMin': 21 * 60 + 30,
      'color': 'amber',
      'alertOn': false,
      'alertBefore': 15,
      'journal': <Map<String, dynamic>>[],
      'checklist': ['HTF bias set', 'News checked', 'Risk defined'],
      'skipUntil': null,
    },
    {
      'id': 'kz2',
      'name': 'London',
      'startMin': 2 * 60,
      'endMin': 5 * 60,
      'color': 'sky',
      'alertOn': false,
      'alertBefore': 15,
      'journal': <Map<String, dynamic>>[],
      'checklist': ['HTF bias set', 'News checked', 'Risk defined'],
      'skipUntil': null,
    },
    {
      'id': 'kz3',
      'name': 'NY AM',
      'startMin': 8 * 60 + 30,
      'endMin': 11 * 60,
      'color': 'rose',
      'alertOn': false,
      'alertBefore': 30,
      'journal': <Map<String, dynamic>>[],
      'checklist': ['HTF bias set', 'News checked', 'Risk defined'],
      'skipUntil': null,
    },
    {
      'id': 'kz4',
      'name': 'London Close',
      'startMin': 10 * 60,
      'endMin': 12 * 60,
      'color': 'violet',
      'alertOn': false,
      'alertBefore': 15,
      'journal': <Map<String, dynamic>>[],
      'checklist': ['HTF bias set', 'News checked', 'Risk defined'],
      'skipUntil': null,
    },
    {
      'id': 'kz5',
      'name': 'NY PM',
      'startMin': 13 * 60 + 30,
      'endMin': 16 * 60,
      'color': 'emerald',
      'alertOn': false,
      'alertBefore': 15,
      'journal': <Map<String, dynamic>>[],
      'checklist': ['HTF bias set', 'News checked', 'Risk defined'],
      'skipUntil': null,
    },
  ],
  'trading': {
    'accounts': <Map<String, dynamic>>[],
    'flows': <Map<String, dynamic>>[],
  },
  'subscriptions': <Map<String, dynamic>>[],
  'braindumps': <Map<String, dynamic>>[],
  'groceries': {
    'list': <Map<String, dynamic>>[],
    'pantry': <Map<String, dynamic>>[],
    'members': ['You'],
    'lastRecurringRun': todayPlus(0),
  },
  'body': {
    'macros': {
      'calories': {'used': 0, 'goal': 2400},
      'protein': {'used': 0, 'goal': 180},
      'carbs': {'used': 0, 'goal': 280},
      'fat': {'used': 0, 'goal': 80},
      'water': {'used': 0, 'goal': 10},
    },
    'streak': 0,
    'streakFreezes': 0,
    'meals': <Map<String, dynamic>>[],
    'workouts': <Map<String, dynamic>>[],
    'nextWorkout': '',
  },
  'profile': {
    'notifications': {
      // Reminders default OFF so a fresh install doesn't fire alerts before
      // the user has reviewed quiet hours and per-killzone settings.
      'master': false,
      'leadTime': 15,
      'quietStart': '22:00',
      'quietEnd': '07:00',
      'browserPermission': 'default',
    },
    'dailyReviewTime': '21:00',
  },
};
