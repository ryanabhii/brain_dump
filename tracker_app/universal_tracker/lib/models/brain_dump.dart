/// A captured thought — text, or a voice note transcribed on-device. The
/// legacy `video` payload is preserved opaquely without being modelled yet,
/// since that feature is still deferred.
class BrainDump {
  final String id;
  final String type; // 'text' | 'voice' | 'video'
  final String text;
  final String createdAt; // ISO-8601
  final String? reminderAt; // ISO-8601, optional
  final bool completed;
  final String tag; // personal | work | trading | idea

  /// Full speech-to-text transcript captured when [type] is `voice`.
  /// [text] holds the user-given title; this preserves what was actually said
  /// so the card can show a preview and search can match it later.
  final String? voiceTranscript;

  /// Absolute path to the locally-saved m4a recording captured alongside the
  /// transcript. Lets the user actually listen back to the dump. Null when
  /// the platform refused to record (e.g. mic held exclusively by the
  /// on-device recognizer) — the transcript on its own is still useful.
  final String? voiceAudioPath;

  final Map<String, dynamic>? video;

  const BrainDump({
    required this.id,
    this.type = 'text',
    required this.text,
    required this.createdAt,
    this.reminderAt,
    this.completed = false,
    this.tag = 'personal',
    this.voiceTranscript,
    this.voiceAudioPath,
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
    voiceTranscript: j['voiceTranscript'] as String?,
    voiceAudioPath: j['voiceAudioPath'] as String?,
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
    if (voiceTranscript != null) 'voiceTranscript': voiceTranscript,
    if (voiceAudioPath != null) 'voiceAudioPath': voiceAudioPath,
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
    voiceTranscript: voiceTranscript,
    voiceAudioPath: voiceAudioPath,
    video: video,
  );
}
