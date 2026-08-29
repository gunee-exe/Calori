library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_screen.dart';
import '../providers.dart';

class ActivityStep extends ConsumerWidget {
  const ActivityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).activity;

    return StepScaffold(
      question: 'How active are you?',
      detail: 'Day-to-day movement, not just deliberate exercise.',
      child: Column(
        children: [
          for (final level in ActivityLevel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelCard(
                level: level,
                selected: selected == level,
                onTap: () {
                  ref.read(onboardingProvider.notifier).setActivity(level);
                  ref.read(onboardingCursorProvider.notifier).next();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ActivityLevel level;
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: AppType.body.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Concrete descriptions, not jargon: "desk job, little
                  // exercise" rather than "sedentary, 1.2". The multiplier is
                  // never shown, because it means nothing to the person
                  // choosing.
                  Text(level.description, style: AppType.secondary),
                ],
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
