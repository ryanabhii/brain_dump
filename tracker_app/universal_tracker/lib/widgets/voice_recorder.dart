import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/colors.dart';

/// Result of a finished voice capture. [title] is what the user typed in the
/// "name this note" dialog; [transcript] is the on-device recognition output.
class VoiceCaptureResult {
  final String title;
  final String transcript;
  const VoiceCaptureResult({required this.title, required this.transcript});
}

/// A controllable voice-recorder pill that lives inside a sheet. Tap to
/// start; tap again (or tap "Done") to stop. While recording it shows a
/// pulsing waveform driven by mic volume and the live partial transcript so
/// the user sees their words land in real time.
///
/// After the user stops, [onCaptured] is fired with the final transcript; the
/// caller is responsible for prompting for a title via [promptForTitle].
class VoiceRecorder extends StatefulWidget {
  /// Tint used for the active recording state. Defaults to violet to match
  /// the Capture screen's accent.
  final Color accent;

  /// Called when the user stops recording with a non-empty transcript.
  final void Function(String transcript) onStopped;

  /// Surface fatal errors (mic denied, no recognizer, etc.). The recorder
  /// reverts to idle internally; this is just for messaging.
  final void Function(String message)? onError;

  const VoiceRecorder({
    super.key,
    required this.onStopped,
    this.onError,
    this.accent = AppColors.violet500,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _pulse;
  bool _initialized = false;
  bool _listening = false;
  String _partial = ''; // live in-progress text
  double _level = 0; // 0..1 mic loudness for the pulse animation

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    if (_listening) {
      // Best-effort stop to free the recognizer when the sheet is dismissed
      // mid-recording. Ignore errors — the platform may already be torn down.
      _speech.stop().catchError((_) {});
    }
    super.dispose();
  }

  Future<bool> _ensureReady() async {
    if (_initialized && _speech.isAvailable) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (SpeechRecognitionError e) {
          if (!mounted) return;
          widget.onError?.call(_humanizeError(e.errorMsg));
        },
        onStatus: (status) {
          if (!mounted) return;
          // The platform notifies us when listening ends (timeout or stop).
          // Reflect that in our flag so the UI returns to idle automatically.
          if (status == 'notListening' || status == 'done') {
            setState(() => _listening = false);
          }
        },
      );
    } catch (e) {
      _initialized = false;
      widget.onError?.call('Voice recording unavailable: $e');
    }
    return _initialized;
  }

  String _humanizeError(String raw) => switch (raw) {
    'error_permission' || 'permission' =>
      'Microphone permission denied. Enable it in Settings.',
    'error_no_match' => "Didn't catch that — try again.",
    'error_speech_timeout' => 'Stopped listening (no speech detected).',
    'error_network' => 'Network needed for speech on this device.',
    _ => 'Voice recorder error: $raw',
  };

  Future<void> _start() async {
    final ready = await _ensureReady();
    if (!ready) return;
    setState(() {
      _partial = '';
      _listening = true;
    });
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        if (!mounted) return;
        setState(() => _partial = r.recognizedWords);
      },
      onSoundLevelChange: (lvl) {
        if (!mounted) return;
        // speech_to_text reports level in roughly -2..10 dB units; normalize
        // to 0..1 so the pulse stays visually proportional to volume.
        final norm = ((lvl + 2) / 12).clamp(0.0, 1.0);
        setState(() => _level = norm);
      },
      // 30s pause-after-speech is plenty for a brain dump; cap total at 5 min.
      // Both timeouts (and partial results) live on SpeechListenOptions in
      // v7+; the top-level kwargs are deprecated.
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 5),
      ),
    );
  }

  Future<void> _stop() async {
    if (!_listening) return;
    await _speech.stop();
    setState(() => _listening = false);
    final transcript = _partial.trim();
    if (transcript.isNotEmpty) widget.onStopped(transcript);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _listening
                  ? AppColors.a(accent, 0.5)
                  : AppColors.a(accent, 0.25),
            ),
            color: AppColors.a(accent, _listening ? 0.10 : 0.05),
          ),
          child: Row(
            children: [
              _MicButton(
                listening: _listening,
                accent: accent,
                level: _level,
                pulse: _pulse,
                onTap: _listening ? _stop : _start,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _listening
                          ? 'Listening…'
                          : (_partial.isEmpty
                                ? 'Tap to record'
                                : 'Recorded · tap to redo'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _listening ? accent : AppColors.zinc300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _partial.isEmpty
                          ? 'On-device · no audio is stored'
                          : _partial,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _partial.isEmpty
                            ? AppColors.zinc500
                            : AppColors.zinc200,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (_listening) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _stop,
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Big circular mic button. While listening it pulses with a soft halo whose
/// radius tracks live mic loudness — so the user sees their voice land before
/// any transcript catches up.
class _MicButton extends StatelessWidget {
  final bool listening;
  final Color accent;
  final double level;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.accent,
    required this.level,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, _) {
          final t = listening
              ? 1.0
              : 0.0; // 1 while listening, 0 otherwise
          final halo = listening
              ? (8 + 14 * (pulse.value * 0.4 + level * 0.6))
              : 0.0;
          return Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                AppColors.a(accent, 0.18),
                accent,
                t,
              ),
              boxShadow: listening
                  ? [
                      BoxShadow(
                        color: AppColors.a(accent, 0.45),
                        blurRadius: halo,
                        spreadRadius: halo * 0.2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              listening ? Icons.stop_rounded : Icons.mic_rounded,
              color: listening ? Colors.white : accent,
              size: 22,
            ),
          );
        },
      ),
    );
  }
}

/// Modal that asks the user to title a freshly-captured voice note. Shows the
/// transcript as read-only context underneath so the user can glance at what
/// they said while naming it. Returns `null` if the user cancels.
Future<String?> promptForVoiceTitle(
  BuildContext context, {
  required String transcript,
  Color accent = AppColors.violet500,
}) {
  // Seed the title input with the first ~6 words so the user can accept or
  // tweak rather than typing from scratch.
  final seed = _seedTitleFrom(transcript);
  final controller = TextEditingController(text: seed);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: seed.length,
  );

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.zinc950,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.a(accent, 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.mic_rounded, size: 18, color: accent),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Name this voice note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 80,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: AppColors.zinc100),
                  onSubmitted: (v) =>
                      Navigator.of(ctx).pop(v.trim().isEmpty ? null : v.trim()),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. "Buy groceries"',
                    hintStyle: const TextStyle(color: AppColors.zinc600),
                    filled: true,
                    fillColor: AppColors.zinc900,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.a(accent, 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.zinc800),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: accent, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.a(AppColors.zinc100, 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.a(AppColors.zinc100, 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRANSCRIPT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.zinc500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Text(
                            transcript,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: AppColors.zinc300,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.zinc400),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final v = controller.text.trim();
                        Navigator.of(ctx).pop(v.isEmpty ? null : v);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
}

/// Builds a sensible default title from the first ~6 transcribed words.
/// Capitalised, trimmed to 60 chars, with trailing punctuation removed.
String _seedTitleFrom(String transcript) {
  final words = transcript.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '';
  final take = words.length <= 6 ? words : words.sublist(0, 6);
  var seed = take.join(' ');
  if (seed.length > 60) seed = '${seed.substring(0, 60).trimRight()}…';
  seed = seed.replaceAll(RegExp(r'[.,;:!?]+$'), '');
  if (seed.isEmpty) return '';
  return seed[0].toUpperCase() + seed.substring(1);
}
