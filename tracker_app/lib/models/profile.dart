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

  const Profile({required this.notifications, this.dailyReviewTime = '21:00'});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    notifications: NotificationSettings.fromJson(
      j['notifications'] as Map<String, dynamic>? ?? const {},
    ),
    dailyReviewTime: j['dailyReviewTime'] as String? ?? '21:00',
  );

  Map<String, dynamic> toJson() => {
    'notifications': notifications.toJson(),
    'dailyReviewTime': dailyReviewTime,
  };

  Profile copyWith({
    NotificationSettings? notifications,
    String? dailyReviewTime,
  }) => Profile(
    notifications: notifications ?? this.notifications,
    dailyReviewTime: dailyReviewTime ?? this.dailyReviewTime,
  );
}
