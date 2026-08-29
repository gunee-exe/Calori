library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/pill_button.dart';
import '../onboarding_screen.dart';
import '../providers.dart';
import 'widgets/number_field.dart';

class AgeStep extends ConsumerStatefulWidget {
  const AgeStep({super.key});

  @override
  ConsumerState<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends ConsumerState<AgeStep> {
  late final _controller = TextEditingController(
    text: ref.read(onboardingProvider).age?.toString() ?? '',
  );

  int? get _age => int.tryParse(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _age != null && _age! > 0 && _age! < 120;

  void _continue() {
    if (!_valid) return;

    ref.read(onboardingProvider.notifier).setAge(_age!);

    // The one dead end in the app. Routed here rather than shown as an inline
    // message because there is nothing to correct — this is not a validation
    // failure, it is the end of the flow.
    ref
        .read(onboardingCursorProvider.notifier)
        .go(_age! < 18 ? OnboardingStep.blocked : OnboardingStep.body);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      question: 'How old are you?',
      detail: 'Age changes how much energy your body uses at rest.',
      action: PillButton(
        label: 'Continue',
        onPressed: _valid ? _continue : null,
      ),
      child: NumberField(
        controller: _controller,
        suffix: 'years',
        autofocus: true,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _continue(),
      ),
    );
  }
}
