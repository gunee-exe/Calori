/// Height and weight, in whichever units the user thinks in.
///
/// Both are stored metric — [feetInchesToCm] and [poundsToKg] convert on the
/// way in, and nothing past this screen knows imperial exists. That keeps
/// Mifflin-St Jeor, the BMI checks and every stored profile on one set of
/// units, which is the only way the arithmetic stays checkable.
///
/// The two travel under one switch rather than two. Someone who gives their
/// height in feet and inches almost always gives their weight in pounds, and
/// separate switches would be twice the control for a case nobody has.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/units.dart';
import '../../../core/widgets/number_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../onboarding_screen.dart';
import '../providers.dart';

class BodyStep extends ConsumerStatefulWidget {
  const BodyStep({super.key});

  @override
  ConsumerState<BodyStep> createState() => _BodyStepState();
}

class _BodyStepState extends ConsumerState<BodyStep> {
  /// Focus is requested after the step transition rather than via `autofocus`.
  ///
  /// The AnimatedSwitcher keeps the outgoing step mounted while it fades, so
  /// two autofocus requests overlap and the incoming field loses — the user
  /// lands on a step with no keyboard and has to tap the field themselves.
  final _heightFocus = FocusNode();

  late final _draft = ref.read(onboardingProvider);

  late final _height = TextEditingController(
    text: _draft.usesImperial ? '' : _initial(_draft.heightCm),
  );
  late final _feet = TextEditingController(
    text: _draft.usesImperial && _draft.heightCm != null
        ? '${cmToFeetInches(_draft.heightCm!).feet}'
        : '',
  );
  late final _inches = TextEditingController(
    text: _draft.usesImperial && _draft.heightCm != null
        ? '${cmToFeetInches(_draft.heightCm!).inches}'
        : '',
  );
  late final _weight = TextEditingController(
    text: _draft.weightKg == null
        ? ''
        : _initial(
            _draft.usesImperial
                ? kgToPounds(_draft.weightKg!).roundToDouble()
                : _draft.weightKg,
          ),
  );

  static String _initial(double? value) =>
      value == null ? '' : (value % 1 == 0 ? value.toInt() : value).toString();

  bool get _imperial => ref.watch(onboardingProvider).usesImperial;

  // Accept a comma as a decimal separator: most of continental Europe and
  // much of South Asia types 70,5 rather than 70.5.
  static double? _parse(String text) =>
      double.tryParse(text.replaceAll(',', '.'));

  double? get _heightValue {
    if (!_imperial) return _parse(_height.text);

    // Inches are optional. "Six foot" is a thing people say, and refusing to
    // continue until a 0 is typed would be pedantry.
    final feet = int.tryParse(_feet.text);
    if (feet == null) return null;
    return feetInchesToCm(feet, int.tryParse(_inches.text) ?? 0);
  }

  double? get _weightValue {
    final raw = _parse(_weight.text);
    if (raw == null) return null;
    return _imperial ? poundsToKg(raw) : raw;
  }

  // Ranges wide enough to be inclusive and narrow enough to catch a typo — a
  // misplaced decimal point in a weight quietly wrecks every figure
  // downstream. Checked against the *converted* metric value, so one set of
  // bounds covers both unit systems and neither can drift from the other.
  bool get _valid =>
      _heightValue != null &&
      _heightValue! >= 100 &&
      _heightValue! <= 250 &&
      _weightValue != null &&
      _weightValue! >= 25 &&
      _weightValue! <= 400;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _heightFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _heightFocus.dispose();
    _height.dispose();
    _feet.dispose();
    _inches.dispose();
    _weight.dispose();
    super.dispose();
  }

  /// Switches units, carrying whatever has been typed across.
  ///
  /// Converting rather than clearing matters: someone who fills the fields in
  /// and only then notices the toggle should not have to start again, and a
  /// field emptying itself reads as the app having lost the answer.
  void _switchTo(bool imperial) {
    if (imperial == _imperial) return;

    // Read before the switch, while the getters still parse the old units.
    final cm = _heightValue;
    final kg = _weightValue;

    if (imperial) {
      if (cm != null) {
        final (:feet, :inches) = cmToFeetInches(cm);
        _feet.text = '$feet';
        _inches.text = '$inches';
      }
      if (kg != null) _weight.text = kgToPounds(kg).round().toString();
    } else {
      if (cm != null) _height.text = cm.round().toString();
      if (kg != null) _weight.text = kg.round().toString();
    }

    ref.read(onboardingProvider.notifier).setUnits(imperial);
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
    final imperial = _imperial;

    final decimal = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      LengthLimitingTextInputFormatter(6),
    ];
    final whole = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(2),
    ];

    return StepScaffold(
      question: 'Your height and weight',
      detail: 'Both feed the estimate of how much energy you use in a day.',
      action: PillButton(
        label: 'Continue',
        onPressed: _valid ? _continue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UnitToggle(imperial: imperial, onChanged: _switchTo),
          const SizedBox(height: 18),

          if (imperial)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: NumberField(
                    controller: _feet,
                    focusNode: _heightFocus,
                    label: 'Height',
                    suffix: 'ft',
                    inputFormatters: whole,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberField(
                    controller: _inches,
                    suffix: 'in',
                    inputFormatters: whole,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            )
          else
            NumberField(
              controller: _height,
              focusNode: _heightFocus,
              label: 'Height',
              suffix: 'cm',
              inputFormatters: decimal,
              onChanged: (_) => setState(() {}),
            ),

          const SizedBox(height: 16),
          NumberField(
            controller: _weight,
            label: 'Current weight',
            suffix: imperial ? 'lb' : 'kg',
            inputFormatters: decimal,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _continue(),
          ),
        ],
      ),
    );
  }
}

/// Metric or imperial, for every height and weight the app asks for.
class UnitToggle extends StatelessWidget {
  const UnitToggle({
    super.key,
    required this.imperial,
    required this.onChanged,
  });

  final bool imperial;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PillButton(
            label: 'kg / cm',
            variant: imperial ? PillVariant.surface : PillVariant.primary,
            onPressed: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PillButton(
            label: "lb / ft'in",
            variant: imperial ? PillVariant.primary : PillVariant.surface,
            onPressed: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}
