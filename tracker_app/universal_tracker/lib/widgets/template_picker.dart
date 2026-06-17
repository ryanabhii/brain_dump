import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A horizontal chip strip that lets users pick one of their pre-saved
/// templates to fill the current "add" form. Generic over the template type
/// so it can be reused by every tab — the caller supplies the list, a label
/// extractor, and a tap callback.
///
/// Hidden when the user has no templates of this type yet (nothing to show
/// is better than a confusing empty rail).
class TemplatePicker<T> extends StatelessWidget {
  /// All templates of this type, in render order (caller decides).
  final List<T> templates;

  /// Pull the human-readable label out of [T]. Usually just `(t) => t.name`.
  final String Function(T) labelOf;

  /// Pull an optional secondary line (e.g. "120 kcal · 80g" for meals).
  /// Return null/empty to omit.
  final String? Function(T)? subtitleOf;

  /// Pull an optional icon to lead the chip. Defaults to a small "preset" mark.
  final IconData Function(T)? iconOf;

  /// Tap = apply this template.
  final void Function(T) onPick;

  /// Long-press = edit; null disables editing from the chip.
  final void Function(T)? onLongPress;

  /// Optional accent so the meal sheet (violet) can match the per-screen
  /// theme. Defaults to the app's primary cyan.
  final Color accent;

  /// Label shown above the strip ("Templates", "Presets", etc.).
  final String label;

  const TemplatePicker({
    super.key,
    required this.templates,
    required this.labelOf,
    required this.onPick,
    this.subtitleOf,
    this.iconOf,
    this.onLongPress,
    this.accent = AppColors.cyan500,
    this.label = 'Templates',
  });

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Icon(Icons.bookmark_border, size: 12, color: AppColors.zinc500),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.zinc500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.a(accent, 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${templates.length}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = templates[i];
              final subtitle = subtitleOf?.call(t);
              final icon = iconOf?.call(t) ?? Icons.bookmark;
              return _TemplateChip(
                label: labelOf(t),
                subtitle: subtitle,
                icon: icon,
                accent: accent,
                onTap: () => onPick(t),
                onLongPress:
                    onLongPress == null ? null : () => onLongPress!(t),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TemplateChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasSub = subtitle != null && subtitle!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.a(accent, 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.a(accent, 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  if (hasSub)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.zinc400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
