import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/default_data.dart';
import '../models/brain_dump.dart';
import '../state/app_state.dart';
import '../theme/colors.dart';
import '../utils/auto_route.dart';
import '../widgets/ui.dart';
import '../widgets/voice_recorder.dart';

/// Port of the React `BrainScreen` (Prototype.tsx line 1317): capture quick
/// thoughts, filter open/done/all, and (the improvement) promote a dump that
/// looks like a shopping item straight into the grocery list.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  String _filter = 'open'; // open | done | all

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.data!.braindumps.where((b) {
      return switch (_filter) {
        'open' => !b.completed,
        'done' => b.completed,
        _ => true,
      };
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capture',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Brain dumps · single tap',
                style: TextStyle(fontSize: 13, color: AppColors.zinc500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ActionCard(
            icon: Icons.mic,
            title: 'Quick dump',
            subtitle: 'Type or record',
            tint: AppColors.violet500,
            onTap: () => _openAdd(context),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final f in const ['open', 'done', 'all'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: f[0].toUpperCase() + f.substring(1),
                    active: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    _filter == 'open' ? 'All clear ✨' : 'Nothing here',
                    style: const TextStyle(color: AppColors.zinc500),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _DumpCard(item: items[i]),
                ),
        ),
      ],
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BrainAddSheet(),
    );
  }
}

(Color, Color) _tagColors(String tag) => switch (tag) {
  'trading' => (AppColors.a(AppColors.amber500, 0.15), AppColors.amber400),
  'idea' => (AppColors.a(AppColors.violet500, 0.15), AppColors.violet400),
  'work' => (AppColors.a(AppColors.sky400, 0.15), AppColors.sky400),
  _ => (AppColors.a(AppColors.rose400, 0.15), AppColors.rose400),
};

class _DumpCard extends StatelessWidget {
  final BrainDump item;
  const _DumpCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final (tagBg, tagFg) = _tagColors(item.tag);
    final dest = item.completed ? null : autoRoute(item.text);
    final created = DateFormat('MMM d').format(DateTime.parse(item.createdAt));

    return Opacity(
      opacity: item.completed ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: surfaceCard(radius: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => app.toggleDump(item.id),
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.completed ? AppColors.violet500 : null,
                  border: Border.all(
                    color: item.completed
                        ? AppColors.violet500
                        : AppColors.zinc600,
                  ),
                ),
                child: item.completed
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.type == 'voice') ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 6),
                          child: Icon(
                            Icons.mic_rounded,
                            size: 14,
                            color: item.completed
                                ? AppColors.zinc600
                                : AppColors.violet400,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.type == 'voice'
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: item.completed
                                ? AppColors.zinc500
                                : AppColors.zinc100,
                            decoration: item.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      // Inline playback for voice dumps that captured audio.
                      // The button is only rendered when the file is
                      // present AND still exists on disk — if the user
                      // wiped storage, we silently degrade to text-only.
                      if (item.type == 'voice' &&
                          item.voiceAudioPath != null &&
                          item.voiceAudioPath!.isNotEmpty)
                        _VoicePlayButton(
                          path: item.voiceAudioPath!,
                          tint: item.completed
                              ? AppColors.zinc600
                              : AppColors.violet400,
                        ),
                    ],
                  ),
                  // Voice notes: show a soft "quote" of the transcript so the
                  // user can recall the full thought without tapping in.
                  if (item.type == 'voice' &&
                      item.voiceTranscript != null &&
                      item.voiceTranscript!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.voiceTranscript!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: item.completed
                            ? AppColors.zinc600
                            : AppColors.zinc400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(item.tag, fg: tagFg, bg: tagBg),
                      if (item.reminderAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications,
                              size: 10,
                              color: AppColors.amber400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              DateFormat(
                                'MMM d',
                              ).format(DateTime.parse(item.reminderAt!)),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.amber400,
                              ),
                            ),
                          ],
                        ),
                      if (dest == 'grocery')
                        GestureDetector(
                          onTap: () {
                            app.moveDumpToGrocery(item);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Moved to grocery list'),
                                  duration: Duration(milliseconds: 1200),
                                ),
                              );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.a(AppColors.emerald500, 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.a(AppColors.emerald500, 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 10,
                                  color: AppColors.emerald400,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Move to Grocery',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.emerald400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (dest != null)
                        Text(
                          'looks like · $dest',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.zinc500,
                          ),
                        ),
                      Text(
                        created,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => app.removeDump(item.id),
              child: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.zinc600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small building blocks ──────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.a(tint, 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.a(tint, 0.25), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.zinc400),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.zinc100 : AppColors.zinc900,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.zinc100 : AppColors.zinc800,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: active ? AppColors.zinc900 : AppColors.zinc400,
        ),
      ),
    ),
  );
}

// ── Add sheet ──────────────────────────────────────────────────
class _BrainAddSheet extends StatefulWidget {
  const _BrainAddSheet();
  @override
  State<_BrainAddSheet> createState() => _BrainAddSheetState();
}

class _BrainAddSheetState extends State<_BrainAddSheet> {
  final _text = TextEditingController();
  String? _tag;
  int? _reminderIdx;

  static const _reminders = <(String, num)>[
    ('Later today', 0.25),
    ('Tomorrow', 1),
    ('Next week', 7),
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String? _reminderAt() => _reminderIdx == null
      ? null
      : todayPlus(_reminders[_reminderIdx!].$2);

  /// Text-path save. Voice flow has its own end-to-end handler so the title
  /// prompt + transcript stay in one place.
  void _save() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    context.read<AppState>().addDump(
      text: text,
      tag: _tag,
      reminderAt: _reminderAt(),
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Captured ✨'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  /// Called once the voice recorder stops with a non-empty transcript. Opens
  /// the title dialog, then commits a `voice`-type dump that carries the
  /// transcript and (when available) the locally-saved audio path so the
  /// user can play it back later.
  Future<void> _handleVoiceCapture(
    String transcript,
    String? audioPath,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final title = await promptForVoiceTitle(
      context,
      transcript: transcript,
      accent: AppColors.violet500,
    );
    if (!mounted) return;
    if (title == null) {
      // User cancelled the title prompt — drop the audio too so we don't
      // leak orphaned m4a files into the app's documents directory.
      if (audioPath != null) {
        unawaited(File(audioPath).delete().catchError((_) => File(audioPath)));
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Voice note discarded'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }
    app.addDump(
      text: title,
      tag: _tag,
      reminderAt: _reminderAt(),
      type: 'voice',
      voiceTranscript: transcript,
      voiceAudioPath: audioPath,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          audioPath != null
              ? 'Voice note saved 🎙️ (tap ▶ to listen)'
              : 'Voice note saved 🎙️',
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _surfaceVoiceError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Brain dump',
      children: [
        // Voice recorder lives above the text field — same modal handles
        // both capture modes; the user picks whichever feels faster.
        VoiceRecorder(
          accent: AppColors.violet500,
          onStopped: _handleVoiceCapture,
          onError: _surfaceVoiceError,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: AppColors.zinc800)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR TYPE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.zinc600,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppColors.zinc800)),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _text,
          hint: "What's on your mind?",
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        const SectionLabel('Tag'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final t in const ['personal', 'work', 'trading', 'idea'])
              _ChoiceChip(
                label: t,
                active: _tag == t,
                onTap: () => setState(() => _tag = t),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const SectionLabel('Remind me'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < _reminders.length; i++)
              _ChoiceChip(
                label: _reminders[i].$1,
                active: _reminderIdx == i,
                // Improvement over the prototype: select by index, so the
                // highlight is reliable (the prototype compared freshly-made
                // timestamps, which never matched — Prototype.tsx line 2942).
                onTap: () =>
                    setState(() => _reminderIdx = _reminderIdx == i ? null : i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Save', onPressed: _save),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.violet500 : AppColors.zinc900,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.violet500 : AppColors.zinc800,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.white : AppColors.zinc400,
        ),
      ),
    ),
  );
}

/// Compact play/pause control rendered inline on voice dump cards. Each
/// instance owns its own [AudioPlayer] so multiple cards on the same screen
/// can be toggled independently. The button silently hides itself if the
/// audio file has been deleted from disk between renders — voice notes are
/// still useful as text-only entries in that case.
class _VoicePlayButton extends StatefulWidget {
  final String path;
  final Color tint;
  const _VoicePlayButton({required this.path, required this.tint});

  @override
  State<_VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<_VoicePlayButton> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  bool _playing = false;
  bool _fileMissing = false;

  @override
  void initState() {
    super.initState();
    // Reset back to the play icon when the clip finishes or is otherwise
    // stopped externally, so the UI never lies about playback state.
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
    // Probe existence once. We tolerate a race where the file is deleted
    // later: `play()` will throw and we flip `_fileMissing` then too.
    File(widget.path).exists().then((exists) {
      if (!mounted || exists) return;
      setState(() => _fileMissing = true);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_fileMissing) return;
    try {
      if (_playing) {
        await _player.pause();
      } else {
        // DeviceFileSource handles cross-platform path resolution (the raw
        // string works on Android/iOS/desktop but not consistently on web).
        await _player.play(DeviceFileSource(widget.path));
      }
    } catch (_) {
      // File vanished or codec unsupported on this device — hide the button
      // rather than spamming an error toast on every render.
      if (mounted) setState(() => _fileMissing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fileMissing) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkResponse(
        onTap: _toggle,
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 22,
            color: widget.tint,
          ),
        ),
      ),
    );
  }
}
