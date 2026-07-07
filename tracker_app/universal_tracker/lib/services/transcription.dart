import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// On-device speech-to-text for saved voice notes, backed by whisper.cpp
/// via `whisper_ggml`.
///
/// Audio-first flow: the recorder captures a plain m4a with exclusive mic
/// access (see VoiceRecorder), and transcription runs afterwards from the
/// file — so nothing ever fights over the microphone. The plugin converts
/// the m4a to 16 kHz mono WAV with its bundled ffmpeg before inference, so
/// we can feed it our recordings directly.
class TranscriptionService {
  TranscriptionService._();
  static final TranscriptionService instance = TranscriptionService._();

  /// Multilingual `base` model (~148 MB, downloaded once from Hugging Face
  /// and cached in app support storage). Swap to [WhisperModel.tiny] for
  /// roughly 2x speed at lower accuracy, or a `.en` variant if notes are
  /// always English.
  static const WhisperModel _model = WhisperModel.base;

  final WhisperController _controller = WhisperController();

  /// Only Android / iOS / macOS ship the whisper + ffmpeg native libraries;
  /// the Transcribe button should not be offered elsewhere.
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  /// Whether the model file is already on disk (i.e. transcribing won't
  /// trigger the one-time download). Lets the UI warn before a long wait.
  Future<bool> get modelReady async =>
      File(await _controller.getPath(_model)).exists();

  /// Transcribe the audio file at [audioPath] and return the recognized
  /// text, trimmed. Returns an empty string when whisper heard no speech.
  /// Throws when the model can't be downloaded or inference fails.
  Future<String> transcribeFile(String audioPath) async {
    // No-op when the model is already cached. transcribe() itself does NOT
    // download — without this the native call just fails on first use.
    await _controller.downloadModel(_model);
    final String text;
    try {
      final result = await _controller.transcribe(
        model: _model,
        audioPath: audioPath,
        lang: 'auto',
      );
      // The controller swallows native errors and returns null; surface
      // that as a failure the UI can message, distinct from "heard nothing".
      if (result == null) {
        throw Exception('transcription failed');
      }
      text = result.transcription.text.trim();
    } finally {
      // The plugin writes its converted `<audio>.wav` next to the input and
      // leaves it there; clean it up so voice_notes doesn't double in size
      // with every transcription.
      final leftover = File('$audioPath.wav');
      if (await leftover.exists()) {
        await leftover.delete().catchError((_) => leftover);
      }
    }
    // Whisper labels non-speech audio with bracketed annotations like
    // "[BLANK_AUDIO]" or "(wind blowing)". If that's ALL it produced, treat
    // the recording as containing no speech.
    if (RegExp(r'^[\[(].*[\])]$').hasMatch(text)) return '';
    return text;
  }
}
