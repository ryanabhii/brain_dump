import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/colors.dart';
import '../widgets/ui.dart';
import '../main.dart' show PhoneWidth;

/// Map of avatar accent name → real color. The model stores a stable string
/// so swapping the palette later doesn't invalidate persisted data.
const Map<String, Color> kAvatarColors = {
  'cyan': AppColors.cyan500,
  'violet': AppColors.violet500,
  'rose': AppColors.rose500,
  'emerald': AppColors.emerald500,
  'amber': AppColors.amber500,
  'sky': AppColors.sky400,
};

Color avatarColorFor(String name) => kAvatarColors[name] ?? AppColors.cyan500;

/// A common set of currencies pre-filled in the dropdown. The user can still
/// type any 3-letter ISO 4217 code into the field if theirs isn't listed.
const List<String> kCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'INR',
  'JPY',
  'CNY',
  'AUD',
  'CAD',
  'CHF',
  'SGD',
];

/// Full-page editor for personal profile fields. Pushed from the Profile
/// screen via a navigation route. Holds its own draft state so the user can
/// cancel without committing.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _currency;
  // Height + weight are bound to text fields whose units flip live with the
  // Units toggle; the source-of-truth values are kept in [_heightCm] /
  // [_weightKg] so we never round-trip-lose precision.
  late final TextEditingController _heightInput;
  late final TextEditingController _weightInput;

  String _avatarColor = 'cyan';
  String _sex = '';
  String _units = 'metric';
  DateTime? _dob;
  double _heightCm = 0;
  double _weightKg = 0;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().data!.profile;
    final driveEmail = context.read<AppState>().driveEmail ?? '';
    _name = TextEditingController(text: p.displayName);
    // Auto-fill email from the Drive sign-in when the user hasn't set one,
    // so they get a sensible default after first sign-in.
    _email = TextEditingController(
      text: p.email.isNotEmpty ? p.email : driveEmail,
    );
    _currency = TextEditingController(text: p.defaultCurrency);
    _avatarColor = p.avatarColor;
    _sex = p.sex;
    _units = p.units;
    _dob = p.dob.isEmpty ? null : DateTime.tryParse(p.dob);
    _heightCm = p.heightCm.toDouble();
    _weightKg = p.weightKg.toDouble();
    _heightInput = TextEditingController(text: _formatHeight());
    _weightInput = TextEditingController(text: _formatWeight());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currency.dispose();
    _heightInput.dispose();
    _weightInput.dispose();
    super.dispose();
  }

  // ── Unit helpers ───────────────────────────────────────────────────────

  String _formatHeight() {
    if (_heightCm <= 0) return '';
    if (_units == 'imperial') {
      // Show as decimal inches so the input field stays single-value; users
      // can still type 70 (in) and have it round-trip. Switch to feet'inches
      // later if it becomes a UX ask.
      final inches = _heightCm / 2.54;
      return inches.toStringAsFixed(1);
    }
    return _heightCm.toStringAsFixed(0);
  }

  String _formatWeight() {
    if (_weightKg <= 0) return '';
    if (_units == 'imperial') {
      return (_weightKg * 2.20462).toStringAsFixed(1);
    }
    return _weightKg.toStringAsFixed(1);
  }

  void _toggleUnits(String next) {
    if (next == _units) return;
    setState(() {
      _units = next;
      // Reformat the visible numbers to the new unit without losing the
      // canonical metric value.
      _heightInput.text = _formatHeight();
      _weightInput.text = _formatWeight();
    });
  }

  void _readHeight(String raw) {
    final v = double.tryParse(raw.trim());
    if (v == null || v <= 0) {
      _heightCm = 0;
      return;
    }
    _heightCm = _units == 'imperial' ? v * 2.54 : v;
  }

  void _readWeight(String raw) {
    final v = double.tryParse(raw.trim());
    if (v == null || v <= 0) {
      _weightKg = 0;
      return;
    }
    _weightKg = _units == 'imperial' ? v / 2.20462 : v;
  }

  // ── DOB picker ─────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.cyan500,
            onPrimary: AppColors.zinc950,
            surface: AppColors.zinc900,
            onSurface: AppColors.zinc100,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.zinc950,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => _dob = picked);
  }

  // ── Save ───────────────────────────────────────────────────────────────

  void _save() {
    // Flush the visible inputs into the canonical metric values one last
    // time in case the user edited and tapped Save without unfocusing.
    _readHeight(_heightInput.text);
    _readWeight(_weightInput.text);
    if (!_form.currentState!.validate()) return;
    context.read<AppState>().updateProfileIdentity(
      displayName: _name.text.trim(),
      email: _email.text.trim(),
      avatarColor: _avatarColor,
      dob: _dob == null ? '' : DateFormat('yyyy-MM-dd').format(_dob!),
      sex: _sex,
      heightCm: _heightCm,
      weightKg: _weightKg,
      defaultCurrency: _currency.text.trim().toUpperCase(),
      units: _units,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = avatarColorFor(_avatarColor);
    return PhoneWidth(
      child: Scaffold(
        backgroundColor: AppColors.zinc950,
        appBar: AppBar(
          backgroundColor: AppColors.zinc950,
          elevation: 0,
          title: const Text(
            'Edit profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.cyan300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ── Avatar preview ──
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, AppColors.a(accent, 0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.a(accent, 0.35),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _initialsFor(_name.text),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: accent.computeLuminance() > 0.55
                          ? AppColors.zinc950
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionHeading('Identity'),
              const SizedBox(height: 8),
              _Field(
                label: 'Display name',
                child: TextFormField(
                  controller: _name,
                  decoration: _inputDecoration(hint: 'e.g. John Ray'),
                  style: const TextStyle(color: AppColors.zinc100),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}), // refresh initials preview
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  decoration: _inputDecoration(hint: 'you@example.com'),
                  style: const TextStyle(color: AppColors.zinc100),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null; // optional
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Avatar color',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final entry in kAvatarColors.entries)
                      _ColorDot(
                        color: entry.value,
                        selected: _avatarColor == entry.key,
                        onTap: () => setState(() => _avatarColor = entry.key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionHeading('Body'),
              const SizedBox(height: 8),
              _Field(
                label: 'Date of birth',
                child: InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.zinc900,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.zinc800),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_outlined,
                          size: 16,
                          color: AppColors.zinc500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dob == null
                              ? 'Not set'
                              : DateFormat('MMM d, y').format(_dob!),
                          style: TextStyle(
                            fontSize: 14,
                            color: _dob == null
                                ? AppColors.zinc600
                                : AppColors.zinc100,
                          ),
                        ),
                        const Spacer(),
                        if (_dob != null)
                          GestureDetector(
                            onTap: () => setState(() => _dob = null),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: AppColors.zinc500,
                              ),
                            ),
                          ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.zinc500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Sex',
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final opt in const [
                      ('male', 'Male'),
                      ('female', 'Female'),
                      ('other', 'Other'),
                    ])
                      _SegmentChip(
                        label: opt.$2,
                        active: _sex == opt.$1,
                        onTap: () =>
                            setState(() => _sex = _sex == opt.$1 ? '' : opt.$1),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Units',
                child: Row(
                  children: [
                    Expanded(
                      child: _UnitsButton(
                        label: 'Metric · cm/kg',
                        active: _units == 'metric',
                        onTap: () => _toggleUnits('metric'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _UnitsButton(
                        label: 'Imperial · in/lb',
                        active: _units == 'imperial',
                        onTap: () => _toggleUnits('imperial'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Height (${_units == 'imperial' ? 'in' : 'cm'})',
                      child: TextFormField(
                        controller: _heightInput,
                        decoration: _inputDecoration(
                          hint: _units == 'imperial' ? '70' : '175',
                        ),
                        style: const TextStyle(color: AppColors.zinc100),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalInputFormatter],
                        onChanged: _readHeight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      label: 'Weight (${_units == 'imperial' ? 'lb' : 'kg'})',
                      child: TextFormField(
                        controller: _weightInput,
                        decoration: _inputDecoration(
                          hint: _units == 'imperial' ? '155' : '70',
                        ),
                        style: const TextStyle(color: AppColors.zinc100),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalInputFormatter],
                        onChanged: _readWeight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionHeading('Preferences'),
              const SizedBox(height: 8),
              _Field(
                label: 'Default currency',
                child: TextFormField(
                  controller: _currency,
                  decoration: _inputDecoration(
                    hint: 'USD',
                    suffix: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.zinc500,
                      ),
                      color: AppColors.zinc900,
                      onSelected: (v) => setState(() => _currency.text = v),
                      itemBuilder: (_) => [
                        for (final c in kCurrencies)
                          PopupMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: AppColors.zinc100,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  style: const TextStyle(
                    color: AppColors.zinc100,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Save changes', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers / building blocks ────────────────────────────────────────────

/// Mirrors Profile.initials but works against a live controller value so the
/// avatar preview updates on every keystroke.
String _initialsFor(String name) {
  final n = name.trim();
  if (n.isEmpty) return 'U';
  final parts = n.split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

final _decimalInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9.]'),
);

InputDecoration _inputDecoration({String? hint, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.zinc600),
      filled: true,
      fillColor: AppColors.zinc900,
      isDense: true,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.zinc800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cyan500, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.rose500),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.rose500, width: 1.4),
      ),
    );

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.zinc500,
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.zinc400,
          ),
        ),
      ),
      child,
    ],
  );
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: selected ? Colors.white : Colors.transparent,
          width: 2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.a(color, 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: selected
          ? Icon(
              Icons.check,
              size: 16,
              color: color.computeLuminance() > 0.55
                  ? AppColors.zinc950
                  : Colors.white,
            )
          : null,
    ),
  );
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SegmentChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.cyan500 : AppColors.zinc900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.cyan500 : AppColors.zinc800,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.zinc950 : AppColors.zinc300,
        ),
      ),
    ),
  );
}

class _UnitsButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnitsButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.cyan500 : AppColors.zinc900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.cyan500 : AppColors.zinc800,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.zinc950 : AppColors.zinc300,
        ),
      ),
    ),
  );
}
