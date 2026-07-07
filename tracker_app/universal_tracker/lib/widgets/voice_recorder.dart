import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../theme/colors.dart';

/// Result of a finished voice capture. [title] is what the user typed in the
/// "name this note" dialog; [transcript] is the on-device recognition output;
/// [audioPath] is the local m4a file the user can play back later (null if
/// the platform refused to record alongside the recognizer).
class VoiceCaptureResult {
  final String title;
  final String transcript;
  final String? audioPath;
  const VoiceCaptureResult({
    required this.title,
    required this.transcript,
    this.audioPath,
  });
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
  /// [audioPath] is the saved local file, or null if recording the audio
  /// stream failed (the transcript is still useful on its own).
  final void Function(String transcript, String? audioPath) onStopped;

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
  // Captures the raw audio in parallel with the recognizer so the user can
  // listen to the original brain dump later. Best-effort: on some Android
  // builds the SpeechRecognizer monopolises the mic and `record` returns
  // empty audio — we surface that as a null `audioPath` rather than failing
  // the whole capture.
  final AudioRecorder _recorder = AudioRecorder();
  String? _audioPath;
  late final AnimationController _pulse;
  bool _initialized = false;
  bool _listening = false;
  // True only while we're actively recording. Cleared when the user taps
  // Stop. Used to distinguish a real "user finished" from the platform's
  // transient `notListening`/`done` events that fire between utterances or
  // when Android's per-session cap (~1 min) elapses.
  bool _userStopped = true;
  // Committed text from already-ended listen sessions. We accumulate here
  // because each call to `_speech.listen` resets `recognizedWords`.
  String _finalized = '';
  String _partial = ''; // live in-progress text for the CURRENT session
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
      // mid-recording. Mark as user-stopped so any in-flight status callback
      // doesn't try to restart listening on a disposed widget. Ignore errors
      // — the platform may already be torn down.
      _userStopped = true;
      _speech.stop().catchError((_) {});
      _recorder.stop().catchError((_) => null);
    }
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _ensureReady() async {
    if (_initialized && _speech.isAvailable) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (SpeechRecognitionError e) {
          if (!mounted) return;
          // `error_no_match` and `error_speech_timeout` are fired by Android's
          // SpeechRecognizer during normal pauses in dictation — they are NOT
          // fatal. Swallow them so we don't spam the user or kill the loop;
          // the status handler will simply restart the session.
          if (e.errorMsg == 'error_no_match' ||
              e.errorMsg == 'error_speech_timeout') {
            return;
          }
          // Anything else is genuine: surface it and end the session so the
          // UI doesn't get stuck "listening" forever.
          _userStopped = true;
          widget.onError?.call(_humanizeError(e.errorMsg));
        },
        onStatus: (status) {
          if (!mounted) return;
          // The platform fires `notListening` between utterances and `done`
          // when its internal session ends (Android caps each `listen()` call
          // at roughly one minute). Neither means the USER is done. We treat
          // only an explicit Stop tap (`_userStopped == true`) as terminal;
          // otherwise we transparently re-arm the recognizer so it behaves
          // like a continuous dictation surface.
          if (status != 'done' && status != 'notListening') return;
          // Commit whatever the just-ended session produced.
          if (_partial.isNotEmpty) {
            _finalized = _finalized.isEmpty
                ? _partial
                : '$_finalized $_partial';
            _partial = '';
          }
          if (_userStopped) {
            setState(() => _listening = false);
          } else if (status == 'done') {
            // Only restart on `done` — `notListening` can fire mid-session
            // while the recognizer is still actually capturing audio, and
            // calling `listen()` again then would error out.
            // ignore: discarded_futures
            _listenOnce();
          } else {
            // notListening but not user-stopped: just refresh the displayed
            // (now committed) text without flipping the listening flag.
            setState(() {});
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
    'error_permission' ||
    'permission' => 'Microphone permission denied. Enable it in Settings.',
    'error_no_match' => "Didn't catch that — try again.",
    'error_speech_timeout' => 'Stopped listening (no speech detected).',
    'error_network' => 'Network needed for speech on this device.',
    _ => 'Voice recorder error: $raw',
  };

  Future<void> _start() async {
    final ready = await _ensureReady();
    if (!ready) return;
    setState(() {
      _finalized = '';
      _partial = '';
      _audioPath = null;
      _userStopped = false;
      _listening = true;
    });
    await _startRecording();
    await _listenOnce();
  }

  /// Kick off raw-audio capture into a unique file under the app's documents
  /// directory. Failures are swallowed: transcription is the primary path,
  /// and a missing audio file is acceptable degradation.
  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return;
      final dir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${dir.path}/voice_notes');
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${voiceDir.path}/voice_$ts.m4a';
      await _recorder.start(
        // AAC in an MP4 container plays back natively on every target OS.
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000),
        path: path,
      );
      _audioPath = path;
    } catch (_) {
      // Mic likely held by SpeechRecognizer on this device build. Keep
      // _audioPath null and proceed transcript-only.
      _audioPath = null;
    }
  }

  Future<String?> _stopRecording() async {
    try {
      if (!await _recorder.isRecording()) return _audioPath;
      // `stop()` returns the path it actually wrote to (may differ from what
      // we asked for on web). Prefer it when available.
      final stoppedAt = await _recorder.stop();
      return stoppedAt ?? _audioPath;
    } catch (_) {
      return _audioPath;
    }
  }

  /// Single "arm the recognizer" call. The status handler re-invokes this
  /// every time the platform ends a session, so a long brain-dump survives
  /// Android's ~1-minute per-call cap without the user noticing.
  Future<void> _listenOnce() async {
    if (_userStopped || !mounted) return;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) {
          if (!mounted) return;
          // Android's recognizer flips `finalResult: true` at every pause and
          // then resets `recognizedWords` for the next utterance. If we don't
          // commit here, the next partial overwrites the previous sentence
          // and the user sees their earlier words vanish. So: snapshot the
          // utterance into _finalized as soon as it's marked final.
          if (r.finalResult) {
            final words = r.recognizedWords.trim();
            if (words.isNotEmpty) {
              setState(() {
                _finalized = _finalized.isEmpty ? words : '$_finalized $words';
                _partial = '';
              });
            } else {
              setState(() => _partial = '');
            }
          } else {
            setState(() => _partial = r.recognizedWords);
          }
        },
        onSoundLevelChange: (lvl) {
          if (!mounted) return;
          // speech_to_text reports level in roughly -2..10 dB units;
          // normalize to 0..1 so the pulse tracks volume proportionally.
          final norm = ((lvl + 2) / 12).clamp(0.0, 1.0);
          setState(() => _level = norm);
        },
        // Manual-stop-only model: push both timeouts to the platform max so
        // the recognizer never voluntarily quits. Anything it still ends
        // (Android's internal cap, brief silences) is handled by the status
        // handler restarting `_listenOnce`. `cancelOnError: false` keeps
        // benign `no_match`/`speech_timeout` events from killing the loop.
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(minutes: 5),
          listenFor: const Duration(minutes: 30),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _userStopped = true;
      setState(() => _listening = false);
      widget.onError?.call('Voice recording unavailable: $e');
    }
  }

  Future<void> _stop() async {
    if (!_listening) return;
    // Set the flag FIRST so the status callback that fires after `stop()`
    // doesn't try to restart listening.
    _userStopped = true;
    await _speech.stop();
    final savedPath = await _stopRecording();
    // If the file is empty (mic was monopolised by the recognizer) discard
    // it so we don't keep zero-byte garbage and don't show a useless play
    // button later.
    String? finalPath = savedPath;
    if (finalPath != null) {
      try {
        final f = File(finalPath);
        if (!await f.exists() || await f.length() == 0) {
          if (await f.exists()) {
            await f.delete();
          }
          finalPath = null;
        }
      } catch (_) {
        finalPath = null;
      }
    }
    setState(() {
      _audioPath = finalPath;
      _listening = false;
    });
    final transcript = ('$_finalized $_partial').trim();
    // The recording is the primary artifact: hand the capture over whenever
    // we have EITHER audio or words. An audio-only note (recognizer heard
    // nothing) is still worth saving — the user can replay it.
    if (transcript.isNotEmpty || finalPath != null) {
      widget.onStopped(transcript, finalPath);
    } else {
      widget.onError?.call('Nothing captured — try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    // Cumulative text the user sees: previously-committed chunks (from prior
    // listen sessions) joined with the live partial from the current one.
    final displayText = ('$_finalized $_partial').trim();
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
                          ? 'Listening… tap Stop when done'
                          : (displayText.isEmpty
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
                      displayText.isEmpty
                          ? 'Transcribed on-device · recording kept on '
                                'this device'
                          : displayText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: displayText.isEmpty
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
          final t = listening ? 1.0 : 0.0; // 1 while listening, 0 otherwise
          final halo = listening
              ? (8 + 14 * (pulse.value * 0.4 + level * 0.6))
              : 0.0;
          return Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(AppColors.a(accent, 0.18), accent, t),
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
/// they said while naming it (hidden when the recognizer heard nothing — an
/// audio-only note is still savable). Returns `null` if the user cancels.
Future<String?> promptForVoiceTitle(
  BuildContext context, {
  required String transcript,
  Color accent = AppColors.violet500,
}) {
  // Seed the title input with the first ~6 words so the user can accept or
  // tweak rather than typing from scratch. Audio-only captures (nothing
  // recognized) get a generic seed so plain "Save" still keeps the recording.
  var seed = _seedTitleFrom(transcript);
  if (seed.isEmpty) seed = 'Voice note';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                if (transcript.isNotEmpty)
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
                  )
                else
                  const Text(
                    'No speech was recognized — the recording is still '
                    'saved and can be replayed from the note.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.zinc500,
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
