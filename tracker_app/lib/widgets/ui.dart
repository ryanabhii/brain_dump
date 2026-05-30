import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// The standard "card" decoration used everywhere in the prototype
/// (`rounded-2xl bg-zinc-900/60 ring-1 ring-zinc-800`).
BoxDecoration surfaceCard({Color? fill, Color? ring, double radius = 16}) =>
    BoxDecoration(
      color: fill ?? AppColors.a(AppColors.zinc900, 0.6),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ring ?? AppColors.zinc800),
    );

/// A small uppercase, wide-tracked label (the `text-[10px] uppercase
/// tracking-wider text-zinc-500` pattern).
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
      color: color ?? AppColors.zinc500,
    ),
  );
}

/// A thin rounded progress bar (the `h-1.5 bg-zinc-800 … rounded-full` bars).
class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    // Animate the fill: grows in on first build and tweens on change.
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: height,
        color: color,
        backgroundColor: AppColors.zinc800,
      ),
    ),
  );
}

/// A small pill / badge (`text-[10px] px-1.5 py-0.5 rounded`).
/// Named `Pill` to avoid clashing with Flutter's built-in `Badge` widget.
class Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const Pill(this.text, {super.key, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
    ),
  );
}

/// A styled text input used inside the "add" sheets.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14, color: AppColors.zinc100),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.zinc600),
      filled: true,
      fillColor: AppColors.zinc900,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.zinc800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan500),
      ),
    ),
  );
}

/// Like [AppTextField] but with an inline type-ahead dropdown backed by
/// [options] (brokers, categories, groceries, …). Bridges to an external
/// [controller] so existing "save" handlers keep reading `controller.text`.
/// Filtering is case-insensitive substring; on focus with an empty field it
/// previews the top options.
class AppAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> options;
  final TextInputType? keyboardType;
  final int maxOptions;

  /// Called when an option is picked from the dropdown (not on free typing).
  final ValueChanged<String>? onSelected;

  /// Called with the current text when editing finishes — on submit or when the
  /// field loses focus. Lets callers persist a typed (not picked) value without
  /// writing on every keystroke.
  final ValueChanged<String>? onSubmitted;
  const AppAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    required this.options,
    this.keyboardType,
    this.maxOptions = 8,
    this.onSelected,
    this.onSubmitted,
  });

  @override
  State<AppAutocompleteField> createState() => _AppAutocompleteFieldState();
}

class _AppAutocompleteFieldState extends State<AppAutocompleteField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Persist a typed (not picked) value when the field loses focus.
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onSubmitted?.call(widget.controller.text);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  InputDecoration get _decoration => InputDecoration(
    hintText: widget.hint,
    hintStyle: const TextStyle(color: AppColors.zinc600),
    filled: true,
    fillColor: AppColors.zinc900,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.zinc800),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.cyan500),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Capture the field width so the dropdown can match it.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focus,
          onSelected: widget.onSelected,
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            final matches = q.isEmpty
                ? widget.options
                : widget.options.where((o) => o.toLowerCase().contains(q));
            return matches.take(widget.maxOptions);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  keyboardType: widget.keyboardType,
                  onSubmitted: (value) {
                    onFieldSubmitted();
                    widget.onSubmitted?.call(value);
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.zinc100,
                  ),
                  decoration: _decoration,
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            final list = options.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: AppColors.zinc900,
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: width,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.zinc800),
                      itemBuilder: (context, i) => InkWell(
                        onTap: () => onSelected(list[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            list[i],
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.zinc200,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The cyan "Save" button used across sheets.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.cyan500,
      foregroundColor: AppColors.zinc950,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

/// A bottom-sheet container: rounded top, dark background, keyboard-aware,
/// with a bold title — so each "add" form only has to supply its fields.
class SheetShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SheetShell({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.zinc950,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.zinc800)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A round, outlined icon button (the small "+" in screen headers).
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.zinc900,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.zinc800),
      ),
      child: Icon(icon, size: 18, color: AppColors.zinc300),
    ),
  );
}

/// Wraps a tappable card/button and gives it a subtle press-scale animation
/// (the Tailwind `active:scale-[0.98]` feel).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  double _scale = 1;
  void _set(double v) => setState(() => _scale = v);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) => _set(0.97),
    onTapUp: (_) => _set(1),
    onTapCancel: () => _set(1),
    child: AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}
