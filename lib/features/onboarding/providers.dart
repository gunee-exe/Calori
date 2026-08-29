/// Onboarding state (UC-01, UC-02).
///
/// Collects the profile one question at a time and runs it through
/// [GoalEngine] live, so a refusal or a correction appears at the input that
/// caused it rather than at the end of the flow.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/goal_engine.dart';
import '../../domain/goal_result.dart';
import '../../domain/models/enums.dart';

part 'providers.g.dart';

/// The steps, in order. [OnboardingStep.blocked] is not reachable by
/// navigation — the age step routes there and there is no way back out, which
/// is the point.
enum OnboardingStep { sex, age, body, target, activity, result, blocked }

/// Answers gathered so far. Every field is nullable because the flow is
/// resumable and a half-filled draft is a normal state, not an error.
class OnboardingDraft {
  const OnboardingDraft({
    this.sex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.weeks = 12,
    this.activity,
  });

  final Sex? sex;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;

  /// The timeframe asked for. Twelve weeks is a default, not a recommendation:
  /// long enough that the 7700 kcal/kg approximation holds, short enough to
  /// feel real.
  final int weeks;

  final ActivityLevel? activity;

  OnboardingDraft copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    int? weeks,
    ActivityLevel? activity,
  }) => OnboardingDraft(
    sex: sex ?? this.sex,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    weeks: weeks ?? this.weeks,
    activity: activity ?? this.activity,
  );

  /// Whether the engine can be run. Activity is the last input, so everything
  /// before the activity step yields no preview.
  bool get isComplete =>
      sex != null &&
      age != null &&
      heightCm != null &&
      weightKg != null &&
      targetWeightKg != null &&
      activity != null;

  /// Enough to judge the *target weight* even though activity is still unknown.
  ///
  /// The BMI safety rules depend only on height and weight, so an unsafe target
  /// can be refused on the step where it is entered rather than three screens
  /// later. Activity is stubbed with a middle value purely to satisfy the
  /// engine's signature; it cannot change a BMI refusal.
  bool get canPreviewTarget =>
      sex != null &&
      age != null &&
      heightCm != null &&
      weightKg != null &&
      targetWeightKg != null;

  GoalRequest toRequest({DateTime? today}) => GoalRequest(
    sex: sex!,
    age: age!,
    heightCm: heightCm!,
    weightKg: weightKg!,
    targetWeightKg: targetWeightKg!,
    activity: activity ?? ActivityLevel.moderate,
    weeks: weeks,
    today: today ?? DateTime.now(),
  );
}

/// The draft must outlive any individual step.
///
/// `@riverpod` is auto-dispose by default, and each step only reads this while
/// it is on screen — so without keepAlive the provider is torn down the instant
/// a step unmounts and every answer is silently discarded. The flow still
/// advances, which is what makes it so easy to miss: you reach the last screen
/// with an empty draft.
@Riverpod(keepAlive: true)
class Onboarding extends _$Onboarding {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void setSex(Sex value) => state = state.copyWith(sex: value);
  void setAge(int value) => state = state.copyWith(age: value);
  void setHeight(double value) => state = state.copyWith(heightCm: value);
  void setWeight(double value) => state = state.copyWith(weightKg: value);
  void setActivity(ActivityLevel value) =>
      state = state.copyWith(activity: value);

  void setTargetWeight(double value) =>
      state = state.copyWith(targetWeightKg: value);

  void setWeeks(int value) => state = state.copyWith(weeks: value);

  /// Accepts the maintenance (or corrected) target offered after a refusal.
  void acceptMaintenance() =>
      state = state.copyWith(targetWeightKg: state.weightKg);
}

/// The current step.
///
/// Kept alive for the same reason as the draft: the two must not be able to
/// disagree about how far through the flow the user is.
@Riverpod(keepAlive: true)
class OnboardingCursor extends _$OnboardingCursor {
  @override
  OnboardingStep build() => OnboardingStep.sex;

  void go(OnboardingStep step) => state = step;

  void next() {
    const steps = OnboardingStep.values;
    final index = steps.indexOf(state);
    if (index < 0 || state == OnboardingStep.result) return;
    if (state == OnboardingStep.blocked) return;
    state = steps[index + 1];
  }

  void back() {
    // No way back from the age refusal. That is deliberate: a dead end that
    // can be reversed by tapping "back" and typing a different number is not a
    // safeguard, it is a speed bump.
    if (state == OnboardingStep.blocked) return;

    const steps = OnboardingStep.values;
    final index = steps.indexOf(state);
    if (index > 0) state = steps[index - 1];
  }
}

/// The engine's verdict on the draft as it currently stands.
///
/// Null until there is enough to judge. Recomputed on every keystroke, which is
/// what lets the target screen correct a too-fast rate while the user is still
/// looking at the input that caused it.
@Riverpod(keepAlive: true)
GoalResult? goalPreview(Ref ref) {
  final draft = ref.watch(onboardingProvider);
  if (!draft.canPreviewTarget) return null;
  return GoalEngine.calculate(draft.toRequest());
}
