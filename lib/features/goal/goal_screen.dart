/// The goal, viewable and changeable (UC-10).
///
/// Changing a goal takes effect **from today forward**. Past days keep the
/// target that was in force when they were logged — a day you hit is a day you
/// hit, and retroactively re-judging history would be both dishonest and
/// demoralising.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_label.dart';
import '../../domain/repositories/diary_repository.dart';
import '../home/providers.dart';
import '../sources/sources_screen.dart';
import 'edit_goal_screen.dart';

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            const Text('Goal', style: AppType.screenTitle),
            const SizedBox(height: 20),
            if (profile == null)
              const _NoProfile()
            else ...[
              _TargetCard(profile: profile),
              const SizedBox(height: 20),
              const SectionLabel('You'),
              const SizedBox(height: 12),
              _BodyCard(profile: profile),
              const SizedBox(height: 20),
              PillButton(
                label: 'Change goal',
                variant: PillVariant.surface,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditGoalScreen(profile: profile),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
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
            const SizedBox(height: 24),
            Text(
              'Calori estimates. It does not diagnose, treat, or replace advice '
              'from a doctor or dietitian.',
              style: AppType.caption.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoProfile extends StatelessWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context) {
    return const CaloriCard(
      child: Text('No goal set yet.', style: AppType.body),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: SectionLabel('Daily target')),
          const SizedBox(height: 6),
          Center(
            child: Text(
              formatKcal(profile.dailyKcal.toDouble()),
              style: AppType.goalTarget.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Macro(
                label: 'Protein',
                value: profile.dailyProteinG,
                colour: AppColors.primary,
              ),
              _Macro(
                label: 'Carbs',
                value: profile.dailyCarbsG,
                colour: AppColors.carbs,
              ),
              _Macro(
                label: 'Fat',
                value: profile.dailyFatG,
                colour: AppColors.fat,
              ),
            ],
          ),
        ],
      ),
    );
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

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      child: Column(
        children: [
          _Row(
            label: 'Current weight',
            value: '${formatGrams(profile.weightKg)} kg',
          ),
          const Divider(height: 22),
          _Row(
            label: 'Target weight',
            value: '${formatGrams(profile.targetWeightKg)} kg',
          ),
          const Divider(height: 22),
          _Row(label: 'Height', value: '${formatGrams(profile.heightCm)} cm'),
          const Divider(height: 22),
          _Row(label: 'Activity', value: profile.activity.label),
          if (profile.targetDate != null) ...[
            const Divider(height: 22),
            _Row(
              label: 'On track for',
              value: formatDayKeyShort(
                profile.targetDate!.year * 10000 +
                    profile.targetDate!.month * 100 +
                    profile.targetDate!.day,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppType.secondary)),
        Text(value, style: AppType.body),
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
