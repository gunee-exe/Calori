/// The goal engine: profile in, safe daily target out.
///
/// Pure Dart. No I/O, no Flutter imports, no clock of its own — [GoalRequest]
/// carries `today` so every rule is deterministically testable.
///
/// The safety constraints in [GoalEngine.calculate] are the reason this file
/// exists, and they are applied in a fixed order. Reordering them changes which
/// message a user sees, so the order is part of the contract, not an
/// implementation detail.
library;

import 'dart:math' as math;

import 'goal_result.dart';
import 'models/enums.dart';

/// Everything the engine needs. Immutable, and free of any ambient state.
class GoalRequest {
  const GoalRequest({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activity,
    required this.weeks,
    required this.today,
    this.weeklyRateKg,
  });

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final ActivityLevel activity;

  /// The timeframe the user asked for, in weeks. Ignored for maintenance, and
  /// ignored for the *rate* when [weeklyRateKg] is given.
  final int weeks;

  /// The rate the user chose directly, in kg per week. Optional.
  ///
  /// Onboarding asks for a timeframe, so it leaves this null and the rate is
  /// derived from [weeks]. The Goal screen asks for a **rate** instead, and
  /// converting that into whole weeks and back quantises it badly: 3 kg at
  /// 0.95 kg/week is 3.16 weeks, which rounds up to 4 and reads back as
  /// 0.75 kg/week — a 220 kcal error in the daily target. Short goals at fast
  /// rates lose the most, which is exactly where the number matters.
  ///
  /// Ignored unless positive, so a nonsense value falls back to [weeks] rather
  /// than producing a division by zero or a negative deficit.
  final double? weeklyRateKg;

  /// The chosen rate, or null when the timeframe is what was asked for.
  double? get _rate =>
      (weeklyRateKg != null && weeklyRateKg! > 0) ? weeklyRateKg : null;

  /// Injected rather than read from the system clock, so date assertions in
  /// tests are stable.
  final DateTime today;
}

abstract final class GoalEngine {
  /// Energy in one kilogram of body mass, by the standard rule of thumb.
  ///
  /// This figure overestimates loss over long horizons because it ignores
  /// metabolic adaptation — TDEE falls as bodyweight does. It is a reasonable
  /// approximation over a 6–12 week goal and wrong over a year, which is part
  /// of why the app clamps aggressive timeframes rather than honouring them.
  ///
  /// Flagged in `01-concept.md` as needing a citation before it is defended.
  static const kcalPerKg = 7700.0;

  /// Maximum safe rate, as a fraction of bodyweight per week.
  static const maxWeeklyRateFraction = 0.01;

  /// The lower bound of the healthy BMI range.
  static const minHealthyBmi = 18.5;

  /// Grams of protein per kg of bodyweight.
  ///
  /// At the prototype's reference profile (78 kg) this yields the 140 g target
  /// the design shows, which is where the figure comes from.
  ///
  /// Known limitation: for a user with a high BMI this over-prescribes, because
  /// it scales with total mass rather than lean mass. Revisit before this is
  /// presented as clinical guidance.
  static const proteinGPerKg = 1.8;

  /// Share of daily energy from fat, before the per-kg floor is applied.
  static const fatEnergyShare = 0.25;

  /// Minimum fat intake per kg of bodyweight, for hormonal health. Binds
  /// instead of [fatEnergyShare] at low calorie targets.
  static const minFatGPerKg = 0.6;

  /// The protein floor [_macros] falls back to when the calorie target cannot
  /// fund [proteinGPerKg]. Still within the range usually given for preserving
  /// lean mass in a deficit; it is a fallback, not a recommendation.
  static const minProteinGPerKg = 1.2;

  /// The furthest ahead a target date is ever projected.
  ///
  /// Ten years. Past this the 7700 kcal/kg approximation has long stopped
  /// meaning anything, and the alternative is worse: a rate of a few grams a
  /// week divides into a date centuries out, which [_formatDate] renders as a
  /// perfectly cheerful "12 March".
  static const maxProjectionWeeks = 520.0;

  /// Applies every safety rule and returns a target, a correction, or a refusal.
  static GoalResult calculate(GoalRequest r) {
    // ---- 1. Age. The only hard stop with no way forward. ----------------
    if (r.age < 18) {
      return const GoalRefused(
        reason: RefusalReason.minor,
        message:
            'Calori is built for adults. Calorie targets for under-18s depend '
            'on growth and development, and getting them wrong does real harm. '
            'Please talk to a doctor or a parent or guardian about this '
            'instead.',
        // Deliberately null. There is no safe alternative to offer here, and
        // offering one would be a bypass.
        alternative: null,
      );
    }

    final tdee = _tdee(r);
    final direction = _directionFor(r);
    final bmi = _bmi(r.weightKg, r.heightCm);
    final targetBmi = _bmi(r.targetWeightKg, r.heightCm);

    // ---- 2. Unsafe weight. ----------------------------------------------
    // Order matters. If someone is already underweight and wants to lose, their
    // target is necessarily lower still, so the target-weight check below would
    // always fire first and hand them the less useful message. Their *current*
    // weight is the relevant fact, so it is tested first.
    if (bmi < minHealthyBmi && direction == GoalDirection.lose) {
      return GoalRefused(
        reason: RefusalReason.alreadyUnderweight,
        message:
            'You are already below a healthy weight for your height, so Calori '
            'will not help you lose more. Maintaining where you are is the '
            'safer plan, and worth talking through with a doctor.',
        alternative: _maintenanceTarget(r, tdee),
      );
    }

    if (targetBmi < minHealthyBmi) {
      // For someone trying to *gain*, refusing outright and offering only
      // maintenance would block a move in the healthy direction. So the
      // alternative offered is a gain to the lightest healthy weight, not a
      // freeze at the current one. The unsafe target is still refused.
      final alternative = direction == GoalDirection.gain
          ? _targetFor(
              r,
              tdee: tdee,
              direction: GoalDirection.gain,
              goalWeightKg: _weightAtBmi(minHealthyBmi, r.heightCm),
            )
          : _maintenanceTarget(r, tdee);

      return GoalRefused(
        reason: RefusalReason.targetUnderweight,
        message:
            'That target is below a healthy weight for your height. The lowest '
            'weight in the healthy range for you is about '
            '${_weightAtBmi(minHealthyBmi, r.heightCm).round()} kg.',
        alternative: alternative,
      );
    }

    // ---- Maintenance passes straight through. ---------------------------
    if (direction == GoalDirection.maintain) {
      return GoalAccepted(_maintenanceTarget(r, tdee));
    }

    // ---- 3. Clamp the rate to 1% of bodyweight per week. -----------------
    final totalChangeKg = (r.weightKg - r.targetWeightKg).abs();
    final requestedWeeks = math.max(1, r.weeks);
    final maxRate = r.weightKg * maxWeeklyRateFraction;

    // A rate given directly is honoured as given. Deriving it from whole weeks
    // is lossy in the direction that matters: the Goal screen's steppers set a
    // rate, and round-tripping 0.95 kg/week through `ceil(3 / 0.95) = 4` gave
    // back 0.75 — the card then showed a target 220 kcal from the one the
    // chosen rate implies. Onboarding still asks for a timeframe and still
    // gets exactly the old behaviour.
    final requestedRate = r._rate ?? totalChangeKg / requestedWeeks;

    final requestedDate = _dateAfterWeeks(
      r.today,
      r._rate == null
          ? requestedWeeks.toDouble()
          : math.min(maxProjectionWeeks, totalChangeKg / r._rate!),
    );

    var rate = requestedRate;
    var reason = <AdjustmentReason>[];

    if (requestedRate > maxRate) {
      rate = maxRate;
      reason = [AdjustmentReason.rateTooFast];
    }

    // ---- 4 & 5. Deficit, then the calorie floor. -------------------------
    var dailyDelta = rate * kcalPerKg / 7;
    final floor = r.sex.calorieFloor;

    if (direction == GoalDirection.lose) {
      // A maintenance need at or below the floor means no safe deficit exists.
      // Saying so plainly is better than issuing a target that cannot work.
      if (tdee <= floor) {
        return GoalAdjusted(
          target: _targetFrom(
            r,
            tdee: tdee,
            dailyKcal: tdee.round(),
            direction: GoalDirection.maintain,
            ratePercentPerWeek: 0,
            targetDate: null,
          ),
          reason: AdjustmentReason.belowCalorieFloor,
          explanation:
              'Your body already uses about ${tdee.round()} kcal a day, which '
              'is at or below the $floor kcal minimum Calori will suggest. '
              'Eating less than that is not something to do without a '
              "professional's guidance, so this is set to maintain for now.",
          requestedDate: requestedDate,
        );
      }

      if (tdee - dailyDelta < floor) {
        dailyDelta = tdee - floor;
        rate = dailyDelta * 7 / kcalPerKg;
        reason = [...reason, AdjustmentReason.belowCalorieFloor];
      }
    }

    final dailyKcal = direction == GoalDirection.lose
        ? tdee - dailyDelta
        : tdee + dailyDelta;

    final achievableWeeks = math.min(
      maxProjectionWeeks,
      totalChangeKg / rate,
    );
    final honestDate = _dateAfterWeeks(r.today, achievableWeeks);

    final target = _targetFrom(
      r,
      tdee: tdee,
      dailyKcal: dailyKcal.round(),
      direction: direction,
      ratePercentPerWeek: direction == GoalDirection.lose
          ? rate / r.weightKg * 100
          : -(rate / r.weightKg * 100),
      targetDate: honestDate,
    );

    if (reason.isEmpty) return GoalAccepted(target);

    return GoalAdjusted(
      target: target,
      // When both clamps bite, the floor is the one that actually set the
      // number, so it is the one explained.
      reason: reason.last,
      explanation: _explain(reason.last, r, rate, honestDate, floor),
      requestedDate: requestedDate,
    );
  }

  // -------------------------------------------------------------------------

  static String _explain(
    AdjustmentReason reason,
    GoalRequest r,
    double rate,
    DateTime honestDate,
    int floor,
  ) {
    final when = _formatDate(honestDate);
    return switch (reason) {
      AdjustmentReason.rateTooFast =>
        'That timeframe would mean losing more than 1% of your bodyweight a '
            'week, which is faster than is safe to keep up. At a steady rate '
            "you'd reach ${r.targetWeightKg.round()} kg by $when.",
      AdjustmentReason.belowCalorieFloor =>
        'Reaching that date would put you under $floor kcal a day, which is '
            "lower than Calori will suggest. Holding at the floor, you'd reach "
            '${r.targetWeightKg.round()} kg by $when instead.',
    };
  }

  /// Mifflin-St Jeor, then the activity multiplier.
  static double _tdee(GoalRequest r) {
    final bmr =
        10 * r.weightKg +
        6.25 * r.heightCm -
        5 * r.age +
        r.sex.bmrConstant;
    return bmr * r.activity.factor;
  }

  static double _bmi(double weightKg, double heightCm) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  static double _weightAtBmi(double bmi, double heightCm) {
    final m = heightCm / 100;
    return bmi * m * m;
  }

  static GoalDirection _directionFor(GoalRequest r) {
    // Half a kilo of slack: nobody selecting a target within rounding distance
    // of their current weight means "lose weight".
    const epsilon = 0.5;
    if (r.targetWeightKg < r.weightKg - epsilon) return GoalDirection.lose;
    if (r.targetWeightKg > r.weightKg + epsilon) return GoalDirection.gain;
    return GoalDirection.maintain;
  }

  static GoalTarget _maintenanceTarget(GoalRequest r, double tdee) {
    return _targetFrom(
      r,
      tdee: tdee,
      dailyKcal: tdee.round(),
      direction: GoalDirection.maintain,
      ratePercentPerWeek: 0,
      targetDate: null,
    );
  }

  /// Builds a target for an arbitrary goal weight, used when offering an
  /// alternative after a refusal.
  static GoalTarget _targetFor(
    GoalRequest r, {
    required double tdee,
    required GoalDirection direction,
    required double goalWeightKg,
  }) {
    final rate = r.weightKg * maxWeeklyRateFraction;
    final totalChange = (goalWeightKg - r.weightKg).abs();
    final dailyDelta = rate * kcalPerKg / 7;

    return _targetFrom(
      r,
      tdee: tdee,
      dailyKcal: (tdee + dailyDelta).round(),
      direction: direction,
      ratePercentPerWeek: -maxWeeklyRateFraction * 100,
      targetDate: _dateAfterWeeks(r.today, totalChange / rate),
    );
  }

  static GoalTarget _targetFrom(
    GoalRequest r, {
    required double tdee,
    required int dailyKcal,
    required GoalDirection direction,
    required double ratePercentPerWeek,
    required DateTime? targetDate,
  }) {
    // Targets are shown as round numbers; false precision would imply the
    // underlying model is more exact than it is.
    final kcal = (dailyKcal / 10).round() * 10;
    final macros = _macros(kcal, r.weightKg);

    return GoalTarget(
      dailyKcal: kcal,
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
      direction: direction,
      ratePercentPerWeek: ratePercentPerWeek,
      tdee: tdee,
      targetDate: targetDate,
    );
  }

  /// The macro split for a target the user set by hand.
  ///
  /// Exists so the Goal screen can re-derive carbs and fat from an overridden
  /// calorie or protein figure without restating any of this arithmetic —
  /// including the reconciliation in [_macros], which it would be easy to
  /// forget and which is the whole reason that method was fixed.
  ///
  /// A hand-set [proteinG] is taken as given. It is not clamped, checked, or
  /// quietly improved: overruling the engine is the entire point of it, and the
  /// app has already said what it thinks elsewhere on the card.
  static ({int protein, int carbs, int fat}) macrosFor({
    required int kcal,
    required double weightKg,
    int? proteinG,
  }) {
    if (proteinG == null) return _macros(kcal, weightKg);

    var fatG = math
        .max(fatEnergyShare * kcal / 9, minFatGPerKg * weightKg)
        .round();

    if (proteinG * 4 + fatG * 9 > kcal) {
      final minFatG = (minFatGPerKg * weightKg).round();
      fatG = math.max(minFatG, ((kcal - proteinG * 4) / 9).floor());
    }

    return (
      protein: proteinG,
      carbs: math.max(0, ((kcal - proteinG * 4 - fatG * 9) / 4).round()),
      fat: math.max(0, fatG),
    );
  }

  /// Splits a calorie target into grams of protein, carbs and fat.
  ///
  /// Protein is set first because it is the macro the app makes prominent;
  /// fat takes a share of what remains, subject to a per-kg floor; carbs take
  /// the rest.
  ///
  /// The three are then made to fit inside [kcal]. They did not before: protein
  /// and fat both scale with bodyweight while the target is capped from below
  /// by the calorie floor, so a heavy user on a clamped target overran it and
  /// `carbs` clamped to zero swallowed the evidence. At 120 kg on a 1200 kcal
  /// floor, protein and fat alone came to 1508 kcal — and the card printed
  /// three macros summing to more than the number directly above them.
  ///
  /// **This changes nothing in the ordinary case.** The reconciliation below
  /// runs only when the numbers genuinely do not fit; at every plausible
  /// profile the first two lines are the whole calculation, exactly as before.
  static ({int protein, int carbs, int fat}) _macros(
    int kcal,
    double weightKg,
  ) {
    var proteinG = (proteinGPerKg * weightKg / 5).round() * 5;
    var fatG = math
        .max(fatEnergyShare * kcal / 9, minFatGPerKg * weightKg)
        .round();

    if (proteinG * 4 + fatG * 9 > kcal) {
      // Protein gives way first, down to its floor. Dropping fat is the change
      // with hormonal consequences, so it is asked second.
      final minProteinG = (minProteinGPerKg * weightKg / 5).round() * 5;
      proteinG = math.max(minProteinG, ((kcal - fatG * 9) / 20).floor() * 5);

      if (proteinG * 4 + fatG * 9 > kcal) {
        final minFatG = (minFatGPerKg * weightKg).round();
        fatG = math.max(minFatG, ((kcal - proteinG * 4) / 9).floor());
      }

      // Both at their floors and still over. That is not an arithmetic problem
      // to paper over — it means the target itself is below what this body can
      // be fed on, which the calorie floor was supposed to prevent and does not
      // at high bodyweights. Scaling both to fit keeps the card internally
      // honest; the goal being out of range is a separate conversation, and one
      // the refusal machinery above should eventually be having.
      final over = proteinG * 4 + fatG * 9;
      if (over > kcal) {
        final scale = kcal / over;
        proteinG = (proteinG * scale).floor();
        fatG = (fatG * scale).floor();
      }
    }

    final remaining = kcal - proteinG * 4 - fatG * 9;
    final carbsG = math.max(0, (remaining / 4).round());

    return (protein: proteinG, carbs: carbsG, fat: fatG);
  }

  static DateTime _dateAfterWeeks(DateTime from, double weeks) {
    return DateTime(
      from.year,
      from.month,
      from.day,
    ).add(Duration(days: (weeks * 7).ceil()));
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
}
