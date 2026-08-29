/// Result types for [GoalEngine].
///
/// Sealed on purpose. Every screen that renders a goal must handle refusals and
/// corrections explicitly, and `non_exhaustive_switch_statement` is promoted to
/// an error in `analysis_options.yaml` so the compiler enforces it. A safety
/// rule that can be forgotten at a call site is not a safety rule.
library;

import 'models/enums.dart';

/// A computed daily target and its macro split.
class GoalTarget {
  const GoalTarget({
    required this.dailyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.direction,
    required this.ratePercentPerWeek,
    required this.tdee,
    this.targetDate,
  });

  final int dailyKcal;
  final int proteinG;
  final int carbsG;
  final int fatG;

  final GoalDirection direction;

  /// Signed rate as a percentage of bodyweight per week. Positive is loss,
  /// negative is gain, zero is maintenance. Never exceeds 1.0 in magnitude.
  final double ratePercentPerWeek;

  /// Total daily energy expenditure before any deficit or surplus.
  final double tdee;

  /// When the target weight is reached at this rate. Null for maintenance,
  /// which has no end.
  final DateTime? targetDate;
}

/// Why the engine could not honour the request as stated.
enum RefusalReason {
  /// Under 18. The only hard stop with no path forward.
  minor,

  /// The requested target weight is below a BMI of 18.5.
  targetUnderweight,

  /// The user is already below a BMI of 18.5 and asked to lose more.
  alreadyUnderweight,
}

/// Why the engine changed the numbers the user asked for.
enum AdjustmentReason {
  /// The requested timeframe needed more than 1% of bodyweight per week.
  rateTooFast,

  /// The resulting intake fell below the calorie floor for this user.
  belowCalorieFloor,
}

sealed class GoalResult {
  const GoalResult();
}

/// The request was safe and is used as given.
final class GoalAccepted extends GoalResult {
  const GoalAccepted(this.target);
  final GoalTarget target;
}

/// The request was unsafe in its timing, so the engine slowed it down.
///
/// **Not a rejection.** The user continues with corrected numbers and an honest
/// date. [explanation] is written for the person, not the log, and is shown
/// inline beneath the offending input.
final class GoalAdjusted extends GoalResult {
  const GoalAdjusted({
    required this.target,
    required this.reason,
    required this.explanation,
    required this.requestedDate,
  });

  final GoalTarget target;
  final AdjustmentReason reason;
  final String explanation;

  /// What the user originally asked for, so the UI can show the gap.
  final DateTime requestedDate;

  /// The date actually achievable at the corrected rate.
  DateTime get honestDate => target.targetDate ?? requestedDate;
}

/// The request cannot be served safely.
///
/// [alternative] carries a maintenance target where one is appropriate, so the
/// UI can offer a way forward in a single tap rather than leaving a dead end.
/// It is null only for [RefusalReason.minor], which is a genuine stop.
final class GoalRefused extends GoalResult {
  const GoalRefused({
    required this.reason,
    required this.message,
    this.alternative,
  });

  final RefusalReason reason;

  /// Plain language, addressed to the user. Rendered inline at the input that
  /// caused it — never in a modal.
  final String message;

  final GoalTarget? alternative;
}
