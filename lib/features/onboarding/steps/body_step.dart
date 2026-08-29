library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/pill_button.dart';
import '../onboarding_screen.dart';
import '../providers.dart';
import 'widgets/number_field.dart';

class BodyStep extends ConsumerStatefulWidget {
  const BodyStep({super.key});

  @override
  ConsumerState<BodyStep> createState() => _BodyStepState();
}

class _BodyStepState extends ConsumerState<BodyStep> {
  late final _height = TextEditingController(
    text: _initial(ref.read(onboardingProvider).heightCm),
  );
  late final _weight = TextEditingController(
    text: _initial(ref.read(onboardingProvider).weightKg),
  );

  static String _initial(double? value) =>
      value == null ? '' : (value % 1 == 0 ? value.toInt() : value).toString();

  // Accept a comma as a decimal separator: most of continental Europe and
  // much of South Asia types 70,5 rather than 70.5.
  double? get _heightValue =>
      double.tryParse(_height.text.replaceAll(',', '.'));
  double? get _weightValue =>
      double.tryParse(_weight.text.replaceAll(',', '.'));

  // Ranges wide enough to be inclusive and narrow enough to catch a typo — a
  // misplaced decimal point in a weight quietly wrecks every figure downstream.
  bool get _valid =>
      _heightValue != null &&
      _heightValue! >= 100 &&
      _heightValue! <= 250 &&
      _weightValue != null &&
      _weightValue! >= 25 &&
      _weightValue! <= 400;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_valid) return;
    ref.read(onboardingProvider.notifier)
      ..setHeight(_heightValue!)
      ..setWeight(_weightValue!);
    ref.read(onboardingCursorProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      LengthLimitingTextInputFormatter(6),
    ];

    return StepScaffold(
      question: 'Your height and weight',
      detail: 'Both feed the estimate of how much energy you use in a day.',
      action: PillButton(
        label: 'Continue',
        onPressed: _valid ? _continue : null,
      ),
      child: Column(
        children: [
          NumberField(
            controller: _height,
            label: 'Height',
            suffix: 'cm',
            autofocus: true,
            inputFormatters: formatters,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          NumberField(
            controller: _weight,
            label: 'Current weight',
            suffix: 'kg',
            inputFormatters: formatters,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _continue(),
          ),
        ],
      ),
    );
  }
}
