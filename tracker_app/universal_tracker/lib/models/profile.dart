/// Notification preferences (master switch, default lead-time, quiet hours).
class NotificationSettings {
  final bool master;
  final int leadTime; // minutes: 5 | 15 | 30
  final String quietStart; // "HH:mm"
  final String quietEnd;
  final String browserPermission; // default | granted | denied (web only)

  const NotificationSettings({
    this.master = true,
    this.leadTime = 15,
    this.quietStart = '22:00',
    this.quietEnd = '07:00',
    this.browserPermission = 'default',
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> j) =>
      NotificationSettings(
        master: j['master'] as bool? ?? true,
        leadTime: (j['leadTime'] as num?)?.toInt() ?? 15,
        quietStart: j['quietStart'] as String? ?? '22:00',
        quietEnd: j['quietEnd'] as String? ?? '07:00',
        browserPermission: j['browserPermission'] as String? ?? 'default',
      );

  Map<String, dynamic> toJson() => {
    'master': master,
    'leadTime': leadTime,
    'quietStart': quietStart,
    'quietEnd': quietEnd,
    'browserPermission': browserPermission,
  };

  NotificationSettings copyWith({
    bool? master,
    int? leadTime,
    String? quietStart,
    String? quietEnd,
    String? browserPermission,
  }) => NotificationSettings(
    master: master ?? this.master,
    leadTime: leadTime ?? this.leadTime,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    browserPermission: browserPermission ?? this.browserPermission,
  );
}

class Profile {
  final NotificationSettings notifications;
  final String dailyReviewTime; // "HH:mm"

  // ── Personal identity ──
  /// Used for the dashboard greeting and the avatar initials. Empty falls
  /// back to "You" in the UI.
  final String displayName;

  /// Optional. Auto-prefilled from Drive sign-in if available; can be
  /// overridden manually.
  final String email;

  /// Tailwind-style accent name (`cyan`, `violet`, `rose`, `emerald`,
  /// `amber`, `sky`). Resolved to a real [Color] at render time. Defaults to
  /// `cyan` to match the app's primary accent.
  final String avatarColor;

  /// ISO yyyy-MM-dd; empty when not provided. Used by Body for macro defaults
  /// once we wire that in. Kept as a string so JSON round-trips cleanly.
  final String dob;

  /// `male` | `female` | `other` | `` (unset). Drives macro/BMR defaults.
  final String sex;

  /// Height in centimetres, 0 = unset. Stored in metric internally; the
  /// edit screen converts to/from cm as the user toggles units.
  final num heightCm;

  /// Current weight in kilograms, 0 = unset. Same metric-internally rule.
  final num weightKg;

  /// Pre-fills new Trading accounts and Spend subscriptions. ISO 4217 code
  /// (`USD`, `EUR`, `INR`, ...).
  final String defaultCurrency;

  /// `metric` (cm + kg) or `imperial` (in + lb). Display-only; storage is
  /// always metric so a flip doesn't drift the underlying numbers.
  final String units;

  /// Which middle bottom-nav tabs the user has pinned. Stored as indices that
  /// match `RootShell._screens` (1=Trading, 2=Spend, 3=Capture, 4=Pantry,
  /// 5=Body). Home (0) and Profile (6) are always pinned and never appear
  /// here. Defaults to all five so existing installs see the same nav.
  final List<int> pinnedNavTabs;

  /// Which dashboard tiles to render, identified by stable string keys (see
  /// `kHomeTileKeys` in dashboard_screen.dart). Order in this list is *not*
  /// honoured — the dashboard renders tiles in its canonical layout order
  /// and just skips any whose key is absent. Empty list = nothing extra
  /// (only the header + sidebar remain).
  final List<String> pinnedHomeTiles;

  const Profile({
    required this.notifications,
    this.dailyReviewTime = '21:00',
    this.displayName = '',
    this.email = '',
    this.avatarColor = 'cyan',
    this.dob = '',
    this.sex = '',
    this.heightCm = 0,
    this.weightKg = 0,
    this.defaultCurrency = 'USD',
    this.units = 'metric',
    this.pinnedNavTabs = const [1, 2, 3, 4, 5],
    this.pinnedHomeTiles = const [
      'killzone',
      'spend',
      'apiBurn',
      'capture',
      'household',
      'streak',
      'body',
      'quickDump',
    ],
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    notifications: NotificationSettings.fromJson(
      j['notifications'] as Map<String, dynamic>? ?? const {},
    ),
    dailyReviewTime: j['dailyReviewTime'] as String? ?? '21:00',
    displayName: j['displayName'] as String? ?? '',
    email: j['email'] as String? ?? '',
    avatarColor: j['avatarColor'] as String? ?? 'cyan',
    dob: j['dob'] as String? ?? '',
    sex: j['sex'] as String? ?? '',
    heightCm: (j['heightCm'] as num?) ?? 0,
    weightKg: (j['weightKg'] as num?) ?? 0,
    defaultCurrency: j['defaultCurrency'] as String? ?? 'USD',
    units: j['units'] as String? ?? 'metric',
    pinnedNavTabs: (j['pinnedNavTabs'] as List?)
            ?.map((e) => (e as num).toInt())
            .where((i) => i >= 1 && i <= 5)
            .toList() ??
        const [1, 2, 3, 4, 5],
    // Older installs don't have this field — fall back to "show everything"
    // so the upgrade path keeps the dashboard looking the same.
    pinnedHomeTiles: (j['pinnedHomeTiles'] as List?)
            ?.whereType<String>()
            .toList() ??
        const [
          'killzone',
          'spend',
          'apiBurn',
          'capture',
          'household',
          'streak',
          'body',
          'quickDump',
        ],
  );

  Map<String, dynamic> toJson() => {
    'notifications': notifications.toJson(),
    'dailyReviewTime': dailyReviewTime,
    'displayName': displayName,
    'email': email,
    'avatarColor': avatarColor,
    'dob': dob,
    'sex': sex,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'defaultCurrency': defaultCurrency,
    'units': units,
    'pinnedNavTabs': pinnedNavTabs,
    'pinnedHomeTiles': pinnedHomeTiles,
  };

  Profile copyWith({
    NotificationSettings? notifications,
    String? dailyReviewTime,
    String? displayName,
    String? email,
    String? avatarColor,
    String? dob,
    String? sex,
    num? heightCm,
    num? weightKg,
    String? defaultCurrency,
    String? units,
    List<int>? pinnedNavTabs,
    List<String>? pinnedHomeTiles,
  }) => Profile(
    notifications: notifications ?? this.notifications,
    dailyReviewTime: dailyReviewTime ?? this.dailyReviewTime,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    avatarColor: avatarColor ?? this.avatarColor,
    dob: dob ?? this.dob,
    sex: sex ?? this.sex,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    units: units ?? this.units,
    pinnedNavTabs: pinnedNavTabs ?? this.pinnedNavTabs,
    pinnedHomeTiles: pinnedHomeTiles ?? this.pinnedHomeTiles,
  );

  /// Year-based age derived from [dob]; returns `null` when dob is unset or
  /// malformed. Wrapping this here keeps the math out of every consumer.
  int? get age {
    if (dob.isEmpty) return null;
    final d = DateTime.tryParse(dob);
    if (d == null) return null;
    final now = DateTime.now();
    var years = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  /// 1-2 letter initials for the avatar bubble. Falls back to "U" when no
  /// name is set (matches the placeholder shown to the user).
  String get initials {
    final n = displayName.trim();
    if (n.isEmpty) return 'U';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
