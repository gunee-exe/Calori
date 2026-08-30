/// First run (UC-01, UC-02).
///
/// One question per screen. Refusals and corrections appear inline at the input
/// that caused them — never in a modal — because a dialog you dismiss teaches
/// nothing, and the whole point of these rules is that the user understands
/// them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import 'providers.dart';
import 'steps/activity_step.dart';
import 'steps/age_step.dart';
import 'steps/blocked_step.dart';
import 'steps/body_step.dart';
import 'steps/result_step.dart';
import 'steps/sex_step.dart';
import 'steps/target_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingCursorProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Progress(step: step),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.durationFor(context, AppMotion.screenIn),
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.standard,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: switch (step) {
                    OnboardingStep.sex => const SexStep(),
                    OnboardingStep.age => const AgeStep(),
                    OnboardingStep.body => const BodyStep(),
                    OnboardingStep.target => const TargetStep(),
                    OnboardingStep.activity => const ActivityStep(),
                    OnboardingStep.result => const ResultStep(),
                    OnboardingStep.blocked => const BlockedStep(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin rule showing how far through the flow the user is.
///
/// Hidden on the blocked screen: there is no progress to report when the flow
/// has ended, and a half-filled bar there would imply there is more to come.
class _Progress extends ConsumerWidget {
  const _Progress({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (step == OnboardingStep.blocked) {
      return const SizedBox(height: 56);
    }

    const total = 5;
    final index = OnboardingStep.values.indexOf(step);
    final progress = ((index + 1) / total).clamp(0.0, 1.0);
    final canGoBack = index > 0 && step != OnboardingStep.result;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: AppLayout.minTapTarget,
            child: canGoBack
                ? IconButton(
                    onPressed: () =>
                        ref.read(onboardingCursorProvider.notifier).back(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: AppMotion.durationFor(context, AppMotion.screenIn),
                  curve: AppMotion.standard,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppLayout.minTapTarget),
        ],
      ),
    );
  }
}

/// Shared frame for a step: a question, optional supporting line, the content,
/// and a continue action pinned to the bottom.
///
/// The question is **fixed above the scroll area** rather than inside it. When
/// the keyboard opens, a scrollable heading gets pushed up and clipped mid-line
/// — you see the descenders of "How old are you?" and nothing else, which
/// reads as a rendering fault rather than as scrolling. The question is the
/// anchor for everything below it, so it stays put and only the content moves.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.question,
    required this.child,
    this.detail,
    this.action,
  });

  final String question;
  final String? detail;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(question, style: AppType.screenTitle),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              // Bottom padding so the last field can scroll clear of the
              // viewport edge. Without it the input card sits flush against
              // the pinned action and its lower rounded corners are clipped,
              // which reads as a broken card rather than as more to scroll.
              padding: const EdgeInsets.only(bottom: 12),
              // The detail line scrolls with the content: it is elaboration,
              // and losing it to the keyboard costs the user nothing.
              children: [
                if (detail != null) ...[
                  Text(detail!, style: AppType.secondary),
                  const SizedBox(height: 24),
                ],
                child,
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
