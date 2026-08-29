library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_screen.dart';
import '../providers.dart';

class SexStep extends ConsumerWidget {
  const SexStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).sex;

    return StepScaffold(
      question: 'First, a couple of basics',
      // Said plainly, because being asked this without explanation is worse
      // than being asked it. The app uses sex twice and nowhere else.
      detail:
          'Calori uses this in two places: the equation that estimates how much '
          'energy your body uses, and the lowest daily calorie figure it will '
          'ever suggest.',
      child: Column(
        children: [
          for (final option in Sex.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SexCard(
                sex: option,
                selected: selected == option,
                onTap: () {
                  ref.read(onboardingProvider.notifier).setSex(option);
                  ref.read(onboardingCursorProvider.notifier).next();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SexCard extends StatelessWidget {
  const _SexCard({
    required this.sex,
    required this.selected,
    required this.onTap,
  });

  final Sex sex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.durationFor(context, AppMotion.fadeIn),
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected ? null : AppShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sex == Sex.male ? 'Male' : 'Female',
                style: AppType.bodyStrong.copyWith(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
