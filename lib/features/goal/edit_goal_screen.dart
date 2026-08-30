/// Changing an existing goal (UC-10).
///
/// Runs the same [GoalEngine] as onboarding, with the same refusals and the
/// same wording. The rules are not a first-run formality — a target that would
/// be refused on day one is refused on day ninety.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_label.dart';
import '../../data/providers.dart';
import '../../domain/goal_engine.dart';
import '../../domain/goal_result.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/diary_repository.dart';
import '../onboarding/steps/widgets/number_field.dart';

class EditGoalScreen extends ConsumerStatefulWidget {
  const EditGoalScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends ConsumerState<EditGoalScreen> {
  late final _weight = TextEditingController(
    text: _plain(widget.profile.weightKg),
  );
  late final _target = TextEditingController(
    text: _plain(widget.profile.targetWeightKg),
  );

  late ActivityLevel _activity = widget.profile.activity;
  int _weeks = 12;
  bool _saving = false;

  static String _plain(double value) =>
      (value % 1 == 0 ? value.toInt() : value).toString();

  double? get _weightValue =>
      double.tryParse(_weight.text.replaceAll(',', '.'));
  double? get _targetValue =>
      double.tryParse(_target.text.replaceAll(',', '.'));

  @override
  void dispose() {
    _weight.dispose();
    _target.dispose();
    super.dispose();
  }

  GoalResult? get _result {
    final weight = _weightValue;
    final target = _targetValue;
    if (weight == null || target == null) return null;
    if (weight < 25 || weight > 400 || target < 25 || target > 400) return null;

    return GoalEngine.calculate(
      GoalRequest(
        sex: widget.profile.sex,
        age: widget.profile.age,
        heightCm: widget.profile.heightCm,
        weightKg: weight,
        targetWeightKg: target,
        activity: _activity,
        weeks: _weeks,
        today: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final refused = result is GoalRefused;

    final target = switch (result) {
      GoalAccepted(:final target) => target,
      GoalAdjusted(:final target) => target,
      _ => null,
    };

    final formatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      LengthLimitingTextInputFormatter(6),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Change goal', style: AppType.bodyStrong),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppLayout.screenPadding,
                children: [
                  NumberField(
                    controller: _weight,
                    label: 'Current weight',
                    suffix: 'kg',
                    inputFormatters: formatters,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  NumberField(
                    controller: _target,
                    label: 'Target weight',
                    suffix: 'kg',
                    inputFormatters: formatters,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Activity'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final level in ActivityLevel.values)
                        SelectableChip(
                          label: level.label,
                          selected: level == _activity,
                          onTap: () => setState(() => _activity = level),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Over how long?', style: AppType.secondary),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _weeks.toDouble(),
                          min: 4,
                          max: 52,
                          divisions: 48,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.border,
                          onChanged: (v) =>
                              setState(() => _weeks = v.round()),
                        ),
                      ),
                      SizedBox(
                        width: 76,
                        child: Text(
                          '$_weeks weeks',
                          style: AppType.body,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSize(
                    duration: AppMotion.durationFor(context, AppMotion.fadeIn),
                    curve: AppMotion.standard,
                    alignment: Alignment.topLeft,
                    child: _Verdict(result: result, target: target),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Changing your goal applies from today. Days you have '
                    'already logged keep the target they were measured '
                    'against.',
                    style: AppType.caption.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PillButton(
                label: _saving ? 'Saving…' : 'Save goal',
                onPressed: target == null || refused || _saving
                    ? null
                    : () => _save(target),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(GoalTarget target) async {
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(diaryRepositoryProvider).saveProfile(
        UserProfile(
          sex: widget.profile.sex,
          age: widget.profile.age,
          heightCm: widget.profile.heightCm,
          weightKg: _weightValue!,
          targetWeightKg: _targetValue!,
          activity: _activity,
          dailyKcal: target.dailyKcal,
          dailyProteinG: target.proteinG,
          dailyCarbsG: target.carbsG,
          dailyFatG: target.fatG,
          targetDate: target.targetDate,
        ),
      );
      navigator.pop();
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

class _Verdict extends StatelessWidget {
  const _Verdict({required this.result, required this.target});

  final GoalResult? result;
  final GoalTarget? target;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox(width: double.infinity);

    final refused = result is GoalRefused;
    final message = switch (result!) {
      GoalRefused(:final message) => message,
      GoalAdjusted(:final explanation) => explanation,
      GoalAccepted() => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: refused ? AppColors.primaryContainer : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: refused ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              message,
              style: AppType.secondary.copyWith(height: 1.55),
            ),
          ),
        if (target != null) ...[
          if (message != null) const SizedBox(height: 12),
          CaloriCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text('New daily target', style: AppType.secondary),
                ),
                Text(
                  '${formatKcal(target!.dailyKcal.toDouble())} kcal',
                  style: AppType.bodyStrong,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
