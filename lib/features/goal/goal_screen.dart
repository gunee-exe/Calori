/// The goal, viewed and changed in place (UC-10).
///
/// The design edits the goal here rather than behind a separate screen: three
/// steppers, with the target recalculating as you press them. Changing a goal
/// is nearly always a nudge, and a nudge should not cost a round trip through
/// a form.
///
/// Changes take effect **from today forward**. Past days keep the target that
/// was in force when they were logged — a day you hit is a day you hit, and
/// retroactively re-judging history would be both dishonest and demoralising.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/stepper_row.dart';
import '../../data/providers.dart';
import '../../domain/goal_engine.dart';
import '../../domain/goal_result.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/diary_repository.dart';
import '../home/providers.dart';
import '../sources/sources_screen.dart';

/// How long after the last stepper press the change is written.
///
/// Pressing "+" five times should be one save, not five. Long enough to absorb
/// a run of taps, short enough that putting the phone down saves the goal.
const _saveDelay = Duration(milliseconds: 700);

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  Timer? _save;

  /// Pending edits, held until they settle. Null means "nothing pending, use
  /// the stored profile", which is what keeps this screen correct if the goal
  /// is changed anywhere else.
  double? _weight;
  double? _target;
  double? _rate;

  @override
  void dispose() {
    _save?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return const _Empty();

    final weight = _weight ?? profile.weightKg;
    final target = _target ?? profile.targetWeightKg;
    final rate = _rate ?? _rateFrom(profile);
    final result = _evaluate(profile, weight, target, rate);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          // Clears the floating nav bar, which draws over this content.
          padding: AppLayout.screenPadding.add(
            const EdgeInsets.only(bottom: AppLayout.navClearance),
          ),
          children: [
            const Text('Goal', style: AppType.screenTitle),
            const SizedBox(height: 18),
            _TargetCard(result: result),
            const SizedBox(height: 14),

            StepperRow(
              label: 'Current weight',
              detail: 'kilograms',
              value: weight,
              suffix: ' kg',
              min: 25,
              max: 400,
              onChanged: (v) => _edit(() => _weight = v),
            ),
            const SizedBox(height: 10),
            StepperRow(
              label: 'Goal weight',
              detail: 'kilograms',
              value: target,
              suffix: ' kg',
              min: 25,
              max: 400,
              onChanged: (v) => _edit(() => _target = v),
            ),
            const SizedBox(height: 10),
            StepperRow(
              label: target > weight ? 'Rate of gain' : 'Rate of loss',
              detail: '% of bodyweight per week',
              value: rate,
              suffix: ' %',
              step: 0.1,
              // The engine caps at 1%/week and corrects anything faster, so
              // the stepper stops there too: the limit is something you can
              // see coming rather than something that happens to you.
              min: 0.1,
              max: 1.0,
              decimals: 1,
              onChanged: (v) => _edit(() => _rate = v),
            ),

            const SizedBox(height: 26),
            const SectionLabel('About'),
            const SizedBox(height: 12),
            _AboutRow(
              label: 'Where the food data comes from',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SourcesScreen(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Changes apply from today. Days you have already logged keep the '
              'target they were measured against.\n\n'
              'Calori estimates. It does not diagnose, treat, or replace '
              'advice from a doctor or dietitian.',
              style: AppType.caption.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(VoidCallback change) {
    setState(change);
    _save?.cancel();
    _save = Timer(_saveDelay, _commit);
  }

  /// The rate implied by a stored profile's target date.
  ///
  /// The profile records a date rather than a rate, so this runs the
  /// arithmetic backwards. Falls back to half a percent — the engine's own
  /// comfortable middle — when there is no date, which is every maintenance
  /// goal.
  double _rateFrom(UserProfile profile) {
    final date = profile.targetDate;
    final delta = (profile.targetWeightKg - profile.weightKg).abs();

    if (date == null || delta < 0.05 || profile.weightKg <= 0) return 0.5;

    final weeks = date.difference(DateTime.now()).inDays / 7;
    if (weeks <= 0) return 0.5;

    return ((delta / weeks) / profile.weightKg * 100).clamp(0.1, 1.0);
  }

  /// Runs the same engine onboarding uses, converting rate into weeks.
  ///
  /// The design thinks in "% per week"; [GoalEngine] thinks in weeks. Neither
  /// is wrong — a rate is what a person chooses, a duration is what the
  /// arithmetic needs.
  GoalResult _evaluate(
    UserProfile profile,
    double weight,
    double target,
    double rate,
  ) {
    final delta = (target - weight).abs();
    final weekly = weight * rate / 100;
    final weeks = delta < 0.05 || weekly <= 0
        ? 12
        : (delta / weekly).ceil().clamp(1, 520);

    return GoalEngine.calculate(
      GoalRequest(
        sex: profile.sex,
        age: profile.age,
        heightCm: profile.heightCm,
        weightKg: weight,
        targetWeightKg: target,
        activity: profile.activity,
        weeks: weeks,
        today: DateTime.now(),
      ),
    );
  }

  Future<void> _commit() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null || !mounted) return;

    final weight = _weight ?? profile.weightKg;
    final target = _target ?? profile.targetWeightKg;
    final rate = _rate ?? _rateFrom(profile);

    final goal = switch (_evaluate(profile, weight, target, rate)) {
      GoalAccepted(:final target) => target,
      GoalAdjusted(:final target) => target,
      // A refused goal is never written. The card already says why, and the
      // steppers stay where they were left, so the correction is one press
      // away rather than a reset.
      GoalRefused() => null,
    };
    if (goal == null) return;

    await ref.read(diaryRepositoryProvider).saveProfile(
      UserProfile(
        sex: profile.sex,
        age: profile.age,
        heightCm: profile.heightCm,
        weightKg: weight,
        targetWeightKg: target,
        activity: profile.activity,
        dailyKcal: goal.dailyKcal,
        dailyProteinG: goal.proteinG,
        dailyCarbsG: goal.carbsG,
        dailyFatG: goal.fatG,
        targetDate: goal.targetDate,
      ),
    );
  }
}

/// The daily target, and one line saying what it means.
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.result});

  final GoalResult result;

  @override
  Widget build(BuildContext context) {
    final target = switch (result) {
      GoalAccepted(:final target) => target,
      GoalAdjusted(:final target) => target,
      GoalRefused() => null,
    };

    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.fadeIn),
      curve: AppMotion.standard,
      child: CaloriCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SectionLabel('Daily target')),
            const SizedBox(height: 6),
            Center(
              child: Text(
                target == null ? '—' : formatKcal(target.dailyKcal.toDouble()),
                style: AppType.goalTarget.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _caption(),
                style: AppType.secondary.copyWith(height: 1.55),
                textAlign: TextAlign.center,
              ),
            ),
            if (target != null && result is! GoalRefused) ...[
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Macro(
                    label: 'Protein',
                    value: target.proteinG,
                    colour: AppColors.primary,
                  ),
                  _Macro(
                    label: 'Carbs',
                    value: target.carbsG,
                    colour: AppColors.carbs,
                  ),
                  _Macro(
                    label: 'Fat',
                    value: target.fatG,
                    colour: AppColors.fat,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _caption() => switch (result) {
    GoalRefused(:final message) => message,
    GoalAdjusted(:final explanation) => explanation,
    GoalAccepted(:final target) => switch (target.direction) {
      GoalDirection.maintain => 'Enough to hold your current weight.',
      _ => _pace(target),
    },
  };

  String _pace(GoalTarget target) {
    final rate = target.ratePercentPerWeek.abs().toStringAsFixed(1);
    final date = target.targetDate;

    if (date == null) return 'At $rate % per week.';

    final key = date.year * 10000 + date.month * 100 + date.day;
    return 'At $rate % per week you reach your target '
        'by ${formatDayKeyShort(key)}.';
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.value,
    required this.colour,
  });

  final String label;
  final int value;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text('$value g', style: AppType.bodyStrong),
        const SizedBox(height: 2),
        Text(label, style: AppType.caption),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.body)),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: Text('No goal set yet.', style: AppType.body)),
    );
  }
}
