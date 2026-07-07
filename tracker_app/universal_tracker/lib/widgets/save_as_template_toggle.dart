import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// "Also save as template" toggle that sits above the primary Save button in
/// every add sheet. A separate widget so the wording, icon, and tap target
/// stay identical everywhere.
class SaveAsTemplateToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Disabled state with a hint — e.g. when the form doesn't have enough data
  /// yet to derive a meaningful template. The toggle stays visible so users
  /// learn it exists, but can't be flipped on until the prerequisites are met.
  final String? disabledReason;

  const SaveAsTemplateToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = disabledReason != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: disabled ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: value
                ? AppColors.a(AppColors.cyan500, 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: value
                  ? AppColors.a(AppColors.cyan500, 0.4)
                  : AppColors.zinc800,
            ),
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                size: 16,
                color: disabled
                    ? AppColors.zinc700
                    : (value ? AppColors.cyan300 : AppColors.zinc500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Also save as template',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: disabled
                            ? AppColors.zinc600
                            : (value ? AppColors.cyan300 : AppColors.zinc300),
                      ),
                    ),
                    if (disabled) ...[
                      const SizedBox(height: 2),
                      Text(
                        disabledReason!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.zinc600,
                        ),
                      ),
                    ] else if (!value) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Reuse one tap next time',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: disabled ? null : onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.cyan500,
                inactiveTrackColor: AppColors.zinc800,
                inactiveThumbColor: AppColors.zinc600,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
