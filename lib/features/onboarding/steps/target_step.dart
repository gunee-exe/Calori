/// Target weight and timeframe.
///
/// The screen the whole goal engine exists for. Everything it can say —
/// refusal, correction, or clean pass — appears inline beneath the input that
/// caused it, updating as the user types.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../domain/goal_result.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_screen.dart';
import '../providers.dart';
import '../../../core/units.dart';
import '../../../core/widgets/number_field.dart';

class TargetStep extends ConsumerStatefulWidget {
  const TargetStep({super.key});

  @override
  ConsumerState<TargetStep> createState() => _TargetStepState();
}

class _TargetStepState extends ConsumerState<TargetStep> {
  /// Delays dismissing the keyboard until typing has actually stopped.
  ///
  /// Without this, typing "50" refuses at "5" — 5 kg really is below a healthy
  /// weight — and the keyboard vanishes before the "0" is typed. The refusal
  /// itself must stay immediate, because that is the whole design; only the
  /// keyboard waits.
  Timer? _settle;

  late final _target = TextEditingController(text: _initial(_seed()));

  static String _initial(double? value) =>
      value == null ? '' : (value % 1 == 0 ? value.toInt() : value).toString();

  /// The value to start from, in whatever units the answers are being given in.
  double? _seed() {
    final draft = ref.read(onboardingProvider);
    final kg = draft.targetWeightKg ?? draft.weightKg;
    if (kg == null) return null;
    return draft.usesPounds ? kgToPounds(kg).roundToDouble() : kg;
  }

  /// Read rather than watched: this step has no unit toggle of its own, so the
  /// preference cannot change underneath it, and [_value] is also called from
  /// `initState` where watching would throw.
  bool get _pounds => ref.read(onboardingProvider).usesPounds;

  /// Always kilograms, whatever is on screen. The bounds check, the draft and
  /// the engine all work in one unit; only the field converts.
  double? get _value {
    final typed = double.tryParse(_target.text.replaceAll(',', '.'));
    if (typed == null) return null;
    return _pounds ? poundsToKg(typed) : typed;
  }

  @override
  void initState() {
    super.initState();
    // Seed the draft so the preview is live on first paint rather than after
    // the first keystroke.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_value != null) {
        ref.read(onboardingProvider.notifier).setTargetWeight(_value!);
      }
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final preview = ref.watch(goalPreviewProvider);

    // A refusal has to be read, so the keyboard gets out of the way.
    //
    // Scrolling the panel into view instead does not work: the keyboard runs
    // its own ensureVisible for the focused field, the two fight, and the
    // result is a half-scrolled field with the explanation still hidden.
    // Dismissing the keyboard is also the honest reading of the moment — the
    // number has been rejected, so there is nothing more to type until the
    // user decides what to do about it.
    ref.listen(goalPreviewProvider, (previous, next) {
      _settle?.cancel();
      if (next is! GoalRefused) return;

      _settle = Timer(const Duration(milliseconds: 900), () {
        if (mounted) FocusManager.instance.primaryFocus?.unfocus();
      });
    });

    // A refusal is a wall: there is nothing to continue to until the input
    // changes or the offered alternative is taken.
    final refused = preview is GoalRefused;
    final valid = _value != null && _value! >= 25 && _value! <= 400;

    return StepScaffold(
      question: 'What are you aiming for?',
      detail: 'Gaining and maintaining are just as valid as losing.',
      action: PillButton(
        label: 'Continue',
        onPressed: valid && !refused
            ? () => ref.read(onboardingCursorProvider.notifier).next()
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NumberField(
            controller: _target,
            label: 'Target weight',
            suffix: _pounds ? 'lb' : 'kg',
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) {
              if (_value != null) {
                ref.read(onboardingProvider.notifier).setTargetWeight(_value!);
              }
              setState(() {});
            },
          ),
          // Directly beneath the field, not after the slider. On a phone with
          // the keyboard open the field sits at the bottom of the viewport,
          // and anything below the slider is off-screen — so a refusal would
          // grey out Continue while its explanation stayed hidden. A dead
          // button with no reason is exactly what this design refuses to do.
          const SizedBox(height: 20),
          AnimatedSize(
            duration: AppMotion.durationFor(context, AppMotion.fadeIn),
            curve: AppMotion.standard,
            alignment: Alignment.topLeft,
            child: _Verdict(result: preview),
          ),
          const SizedBox(height: 24),
          _Timeframe(weeks: draft.weeks),
        ],
      ),
    );
  }
}

class _Timeframe extends ConsumerWidget {
  const _Timeframe({required this.weeks});

  final int weeks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Over how long?', style: AppType.secondary),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: weeks.toDouble(),
                min: 4,
                max: 52,
                divisions: 48,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                onChanged: (value) => ref
                    .read(onboardingProvider.notifier)
                    .setWeeks(value.round()),
              ),
            ),
            SizedBox(
              width: 76,
              child: Text(
                '$weeks weeks',
                style: AppType.body,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The engine's verdict, rendered inline.
///
/// Three shapes, three tones. A refusal explains and offers a way forward; a
/// correction states what changed and why; an accepted goal simply confirms.
/// None of them use red, and none of them are a dialog.
class _Verdict extends ConsumerWidget {
  const _Verdict({required this.result});

  final GoalResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (result) {
      null => const SizedBox(width: double.infinity),
      GoalAccepted(:final target) => _Note(
        tone: _Tone.calm,
        body: target.direction == GoalDirection.maintain
            ? 'Maintaining where you are. Calori will aim for about '
                  '${target.dailyKcal} kcal a day.'
            : 'That works out at about ${target.ratePercentPerWeek.abs()
                  .toStringAsFixed(1)}% of your bodyweight a week.',
      ),
      GoalAdjusted(:final explanation) => _Note(
        tone: _Tone.corrected,
        body: explanation,
      ),
      GoalRefused(:final message, :final alternative) => _Note(
        tone: _Tone.refused,
        body: message,
        action: alternative == null
            ? null
            : _AlternativeButton(
                label: alternative.direction == GoalDirection.maintain
                    ? 'Maintain instead'
                    : 'Aim for a healthy weight instead',
                onTap: () {
                  ref.read(onboardingProvider.notifier).acceptMaintenance();
                  ref.read(onboardingCursorProvider.notifier).next();
                },
              ),
      ),
    };
  }
}

enum _Tone { calm, corrected, refused }

class _Note extends StatelessWidget {
  const _Note({required this.tone, required this.body, this.action});

  final _Tone tone;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // A refusal earns a tinted panel; a correction a hairline border; a clean
    // pass just quiet text. The weight of the container tracks how much the
    // user needs to read it.
    final (background, border) = switch (tone) {
      _Tone.calm => (Colors.transparent, Colors.transparent),
      _Tone.corrected => (AppColors.surface, AppColors.border),
      _Tone.refused => (AppColors.primaryContainer, AppColors.primary),
    };

    return Container(
      width: double.infinity,
      padding: tone == _Tone.calm
          ? EdgeInsets.zero
          : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body,
            style: AppType.secondary.copyWith(
              height: 1.55,
              color: tone == _Tone.refused
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _AlternativeButton extends StatelessWidget {
  const _AlternativeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PillButton(
      label: label,
      variant: PillVariant.primary,
      onPressed: onTap,
      minHeight: 44,
    );
  }
}
