/// The daily target, and the confirm that writes the profile.
///
/// Phrased as a plan rather than a verdict. The number is large because it is
/// the one figure the user will look at every day, not because it is a score.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/calori_card.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/providers.dart';
import '../../../domain/goal_result.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/repositories/diary_repository.dart';
import '../onboarding_screen.dart';
import '../providers.dart';

class ResultStep extends ConsumerStatefulWidget {
  const ResultStep({super.key});

  @override
  ConsumerState<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends ConsumerState<ResultStep> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final result = ref.watch(goalPreviewProvider);

    final target = switch (result) {
      GoalAccepted(:final target) => target,
      GoalAdjusted(:final target) => target,
      _ => null,
    };

    if (target == null || !draft.isComplete) {
      // Only reachable if a step was skipped, which navigation does not allow.
      return const Center(child: CircularProgressIndicator());
    }

    final adjusted = result is GoalAdjusted ? result : null;

    return StepScaffold(
      question: 'Here is your plan',
      action: PillButton(
        label: _saving ? 'Saving…' : 'Start tracking',
        onPressed: _saving ? null : () => _save(target),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CaloriCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SectionLabel('Daily target')),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    formatKcal(target.dailyKcal.toDouble()),
                    style: AppType.goalTarget.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _summary(target),
                    style: AppType.secondary.copyWith(height: 1.55),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // A correction is repeated here rather than left behind on the step
          // that produced it: the number above is not what was asked for, and
          // the user should not have to remember why.
          if (adjusted != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                adjusted.explanation,
                style: AppType.secondary.copyWith(height: 1.55),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const SectionLabel('Macros'),
          const SizedBox(height: 12),
          CaloriCard(
            child: Column(
              children: [
                _MacroRow(
                  label: 'Protein',
                  value: '${target.proteinG} g',
                  colour: AppColors.primary,
                ),
                const Divider(height: 24),
                _MacroRow(
                  label: 'Carbs',
                  value: '${target.carbsG} g',
                  colour: AppColors.carbs,
                ),
                const Divider(height: 24),
                _MacroRow(
                  label: 'Fat',
                  value: '${target.fatG} g',
                  colour: AppColors.fat,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'These are a starting point, not a rule. You can change them at any '
            'time from the Goal screen.',
            style: AppType.secondary.copyWith(height: 1.55),
          ),
        ],
      ),
    );
  }

  String _summary(GoalTarget target) {
    if (target.direction == GoalDirection.maintain) {
      return 'Enough to hold your current weight.';
    }

    final date = target.targetDate;
    final verb = target.direction == GoalDirection.lose ? 'reach' : 'reach';
    if (date == null) return 'Based on what you told us.';

    return 'At this pace you $verb your target around '
        '${formatDayKeyShort(date.year * 10000 + date.month * 100 + date.day)}.';
  }

  Future<void> _save(GoalTarget target) async {
    setState(() => _saving = true);

    final draft = ref.read(onboardingProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(diaryRepositoryProvider).saveProfile(
        UserProfile(
          sex: draft.sex!,
          age: draft.age!,
          heightCm: draft.heightCm!,
          weightKg: draft.weightKg!,
          targetWeightKg: draft.targetWeightKg!,
          activity: draft.activity!,
          dailyKcal: target.dailyKcal,
          dailyProteinG: target.proteinG,
          dailyCarbsG: target.carbsG,
          dailyFatG: target.fatG,
          targetDate: target.targetDate,
        ),
      );
      // No navigation here: the app routes on the profile stream, so writing
      // the row is what moves the user to Home.
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't save your goal. Try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
    required this.colour,
  });

  final String label;
  final String value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppType.body)),
        Text(value, style: AppType.bodyStrong),
      ],
    );
  }
}
