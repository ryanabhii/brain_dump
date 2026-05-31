/// A captured thought — text now, video later (the video feature is deferred,
/// so its payload is preserved opaquely in [video] without being modelled yet).
class BrainDump {
  final String id;
  final String type; // 'text' | 'video'
  final String text;
  final String createdAt; // ISO-8601
  final String? reminderAt; // ISO-8601, optional
  final bool completed;
  final String tag; // personal | work | trading | idea
  final Map<String, dynamic>? video;

  const BrainDump({
    required this.id,
    this.type = 'text',
    required this.text,
    required this.createdAt,
    this.reminderAt,
    this.completed = false,
    this.tag = 'personal',
    this.video,
  });

  factory BrainDump.fromJson(Map<String, dynamic> j) => BrainDump(
    id: j['id'] as String,
    type: j['type'] as String? ?? 'text',
    text: j['text'] as String? ?? '',
    createdAt: j['createdAt'] as String,
    reminderAt: j['reminderAt'] as String?,
    completed: j['completed'] as bool? ?? false,
    tag: j['tag'] as String? ?? 'personal',
    video: j['video'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'text': text,
    'createdAt': createdAt,
    'reminderAt': reminderAt,
    'completed': completed,
    'tag': tag,
    if (video != null) 'video': video,
  };

  BrainDump copyWith({bool? completed, String? text, String? tag}) => BrainDump(
    id: id,
    type: type,
    text: text ?? this.text,
    createdAt: createdAt,
    reminderAt: reminderAt,
    completed: completed ?? this.completed,
    tag: tag ?? this.tag,
    video: video,
  );
}
