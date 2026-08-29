library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';

/// A large numeric input with its unit alongside.
///
/// Big text because these are the numbers the whole app is built on, and
/// because a person entering their weight should not have to squint at it.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.suffix,
    this.label,
    this.autofocus = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;

  /// The unit, shown after the value: "kg", "cm", "years".
  final String suffix;

  final String? label;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppType.secondary),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: AppType.statNumber,
                  decoration: const InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(suffix, style: AppType.secondary),
            ],
          ),
        ),
      ],
    );
  }
}
