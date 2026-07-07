import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../theme/colors.dart';

/// A controllable voice-recorder pill that lives inside a sheet. Tap to
/// start; tap again (or tap "Done") to stop. While recording it shows a
/// pulsing waveform driven by mic volume and a running timer.
///
/// Audio-first design: the recorder is the ONLY client of the microphone.
/// Running a live speech recognizer alongside it doesn't work — Android's
/// SpeechRecognizer is a separate OS process, and when two capture clients
/// contend for the mic the OS cuts one (or both) off, which is how we ended
/// up with milliseconds-long recordings AND empty transcripts. Transcription
/// now happens after the fact, from the saved file, via the Transcribe
/// button on the note card (see TranscriptionService).
class VoiceRecorder extends StatefulWidget {
  /// Tint used for the active recording state. Defaults to violet to match
  /// the Capture screen's accent.
  final Color accent;

  /// Called when the user stops recording and a non-empty audio file was
  /// saved at [audioPath].
  final void Function(String audioPath) onStopped;

  /// Surface fatal errors (mic denied, recorder failed, empty file). The
  /// recorder reverts to idle internally; this is just for messaging.
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
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _ticker;
  late final AnimationController _pulse;
  bool _recording = false;
  // A capture completed this session — only used to switch the idle label to
  // "tap to redo" so the user knows tapping again replaces nothing (each
  // recording is its own file; the previous one is already handed off).
  bool _captured = false;
  Duration _elapsed = Duration.zero;
  double _level = 0; // 0..1 mic loudness for the pulse animation
  String? _audioPath;

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
    _ticker?.cancel();
    _ampSub?.cancel();
    _pulse.dispose();
    if (_recording) {
      // Best-effort stop to release the mic when the sheet is dismissed
      // mid-recording. The partial file is abandoned; it never reached
      // onStopped so nothing references it.
      _recorder.stop().catchError((_) => null);
    }
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      // hasPermission() doubles as the OS permission prompt.
      if (!await _recorder.hasPermission()) {
        widget.onError?.call(
          'Microphone permission denied. Enable it in Settings.',
        );
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${dir.path}/voice_notes');
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${voiceDir.path}/voice_$ts.m4a';
      // Mono voice-tuned AAC in an MP4 container: plays back natively on
      // every target OS, and whisper's ffmpeg pass downmixes to 16 kHz mono
      // for transcription anyway, so stereo/high bitrate would be wasted.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) {
        await _recorder.stop();
        return;
      }
      _audioPath = path;
      _ampSub?.cancel();
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 200))
          .listen((amp) {
            if (!mounted) return;
            // `current` is dBFS: ~-45 in silence, 0 at clipping. Normalize
            // to 0..1 so the halo tracks voice volume proportionally.
            setState(() => _level = ((amp.current + 45) / 45).clamp(0.0, 1.0));
          });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _elapsed += const Duration(seconds: 1));
        }
      });
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
        _level = 0;
      });
    } catch (e) {
      widget.onError?.call('Voice recording unavailable: $e');
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _ticker?.cancel();
    _ampSub?.cancel();
    String? path;
    try {
      // `stop()` returns the path it actually wrote to (may differ from what
      // we asked for on web). Prefer it when available.
      path = await _recorder.stop() ?? _audioPath;
    } catch (_) {
      path = _audioPath;
    }
    setState(() {
      _recording = false;
      _level = 0;
    });
    // Guard against a recorder that silently produced nothing (mic grabbed
    // by another app, storage full): don't hand a dead file to the caller.
    if (path != null) {
      try {
        final f = File(path);
        if (!await f.exists() || await f.length() == 0) {
          if (await f.exists()) {
            await f.delete();
          }
          path = null;
        }
      } catch (_) {
        path = null;
      }
    }
    if (path == null) {
      widget.onError?.call('Nothing captured — try again.');
      return;
    }
    setState(() => _captured = true);
    widget.onStopped(path);
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

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
              color: _recording
                  ? AppColors.a(accent, 0.5)
                  : AppColors.a(accent, 0.25),
            ),
            color: AppColors.a(accent, _recording ? 0.10 : 0.05),
          ),
          child: Row(
            children: [
              _MicButton(
                recording: _recording,
                accent: accent,
                level: _level,
                pulse: _pulse,
                onTap: _recording ? _stop : _start,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _recording
                          ? 'Recording ${_fmt(_elapsed)} · tap Stop when done'
                          : (_captured ? 'Saved · tap to record another' : 'Tap to record'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _recording ? accent : AppColors.zinc300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kept on this device · transcribe on-device from '
                      'the note card',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.zinc500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (_recording) ...[
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

/// Big circular mic button. While recording it pulses with a soft halo whose
/// radius tracks live mic loudness — so the user sees their voice land.
class _MicButton extends StatelessWidget {
  final bool recording;
  final Color accent;
  final double level;
  final AnimationController pulse;
  final VoidCallback onTap;

  const _MicButton({
    required this.recording,
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
          final t = recording ? 1.0 : 0.0; // 1 while recording, 0 otherwise
          final halo = recording
              ? (8 + 14 * (pulse.value * 0.4 + level * 0.6))
              : 0.0;
          return Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(AppColors.a(accent, 0.18), accent, t),
              boxShadow: recording
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
              recording ? Icons.stop_rounded : Icons.mic_rounded,
              color: recording ? Colors.white : accent,
              size: 22,
            ),
          );
        },
      ),
    );
  }
}

/// Modal that asks the user to title a freshly-captured voice note. The
/// recording has no transcript yet (audio-first flow), so instead of showing
/// recognized text it explains where transcription lives. Returns `null` if
/// the user cancels (the caller then discards the audio file).
Future<String?> promptForVoiceTitle(
  BuildContext context, {
  Color accent = AppColors.violet500,
}) {
  const seed = 'Voice note';
  final controller = TextEditingController(text: seed);
  controller.selection = const TextSelection(
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
                const Text(
                  'The recording is saved with the note. Tap the transcribe '
                  'button on its card to turn it into text — on-device, '
                  'whenever you like.',
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
