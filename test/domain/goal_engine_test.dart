import 'package:calori/domain/goal_engine.dart';
import 'package:calori/domain/goal_result.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seven cases `02-phases.md` requires before any goal UI is built, plus
/// the edge cases they imply.
///
/// The engine has no clock of its own, so every date assertion here is exact
/// rather than approximate.
void main() {
  final today = DateTime(2026, 8, 26);

  GoalRequest request({
    Sex sex = Sex.male,
    int age = 30,
    double heightCm = 178,
    double weightKg = 78,
    double targetWeightKg = 70,
    ActivityLevel activity = ActivityLevel.moderate,
    int weeks = 16,
  }) => GoalRequest(
    sex: sex,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
    targetWeightKg: targetWeightKg,
    activity: activity,
    weeks: weeks,
    today: today,
  );

  group('refusals', () {
    test('age 15 is refused outright, with no alternative offered', () {
      final result = GoalEngine.calculate(request(age: 15));

      final refusal = result as GoalRefused;
      expect(refusal.reason, RefusalReason.minor);
      // A minor must not be handed a usable target by any path. An alternative
      // here would be a bypass.
      expect(refusal.alternative, isNull);
      expect(refusal.message, contains('doctor'));
    });

    test('a target below BMI 18.5 is refused, and maintenance is offered', () {
      // 50 kg at 178 cm is a BMI of about 15.8.
      final result = GoalEngine.calculate(request(targetWeightKg: 50));

      final refusal = result as GoalRefused;
      expect(refusal.reason, RefusalReason.targetUnderweight);
      expect(refusal.alternative, isNotNull);
      expect(refusal.alternative!.direction, GoalDirection.maintain);
      // The message must name a concrete alternative weight, not just say no.
      expect(refusal.message, contains('59 kg'));
    });

    test('an already-underweight user is refused before the target is judged', () {
      // 55 kg at 178 cm is a BMI of about 17.4. The target is lower still, so
      // both rules match; the current-weight rule must win because it is the
      // more relevant fact for this person.
      final result = GoalEngine.calculate(
        request(weightKg: 55, targetWeightKg: 52),
      );

      final refusal = result as GoalRefused;
      expect(refusal.reason, RefusalReason.alreadyUnderweight);
      expect(refusal.alternative?.direction, GoalDirection.maintain);
    });

    test('gaining toward an underweight target offers a gain, not a freeze', () {
      // Refusing an underweight target is right, but answering a *gain* request
      // with "maintain instead" would block a move in the healthy direction.
      final result = GoalEngine.calculate(
        request(weightKg: 48, targetWeightKg: 55),
      );

      final refusal = result as GoalRefused;
      expect(refusal.reason, RefusalReason.targetUnderweight);
      expect(refusal.alternative!.direction, GoalDirection.gain);
      expect(refusal.alternative!.dailyKcal, greaterThan(0));
    });
  });

  group('corrections', () {
    test('losing 15 kg in 30 days clamps to 1%/week and reports an honest date', () {
      // 78 -> 63 kg in ~4 weeks is ~3.75 kg/week. The cap is 0.78 kg/week.
      final result = GoalEngine.calculate(
        request(targetWeightKg: 63, weeks: 4),
      );

      final adjusted = result as GoalAdjusted;
      expect(adjusted.reason, AdjustmentReason.rateTooFast);
      expect(adjusted.target.ratePercentPerWeek, closeTo(1.0, 0.001));

      // 15 kg at 0.78 kg/week is 19.23 weeks = 135 days.
      expect(adjusted.honestDate, DateTime(2026, 8, 26).add(const Duration(days: 135)));
      expect(adjusted.honestDate.isAfter(adjusted.requestedDate), isTrue);
      expect(adjusted.explanation, contains('1%'));
    });

    test('an aggressive but legal request clamps to the calorie floor', () {
      // Female, 160 cm, 55 kg, sedentary: TDEE ~1487. A full 1%/week deficit
      // would demand ~882 kcal/day, well under the 1200 floor.
      final result = GoalEngine.calculate(
        request(
          sex: Sex.female,
          heightCm: 160,
          weightKg: 55,
          targetWeightKg: 50,
          activity: ActivityLevel.sedentary,
          weeks: 4,
        ),
      );

      final adjusted = result as GoalAdjusted;
      // Both clamps bite; the floor is the one that set the final number, so it
      // is the one explained.
      expect(adjusted.reason, AdjustmentReason.belowCalorieFloor);
      expect(adjusted.target.dailyKcal, 1200);
      expect(adjusted.honestDate.isAfter(adjusted.requestedDate), isTrue);
    });

    test('no safe deficit exists when maintenance is already at the floor', () {
      // TDEE below the floor: there is no deficit to give. The engine must say
      // so rather than issue a target that cannot work.
      final result = GoalEngine.calculate(
        request(
          sex: Sex.female,
          age: 60,
          heightCm: 150,
          weightKg: 45,
          targetWeightKg: 43,
          activity: ActivityLevel.sedentary,
          weeks: 8,
        ),
      );

      final adjusted = result as GoalAdjusted;
      expect(adjusted.reason, AdjustmentReason.belowCalorieFloor);
      expect(adjusted.target.direction, GoalDirection.maintain);
      expect(adjusted.target.targetDate, isNull);
    });
  });

  group('clean passes', () {
    test('maintenance passes through with no end date', () {
      final result = GoalEngine.calculate(request(targetWeightKg: 78));

      final accepted = result as GoalAccepted;
      expect(accepted.target.direction, GoalDirection.maintain);
      expect(accepted.target.ratePercentPerWeek, 0);
      expect(accepted.target.targetDate, isNull);
      // Maintenance eats at maintenance.
      expect(
        accepted.target.dailyKcal,
        closeTo(accepted.target.tdee, 10),
      );
    });

    test('a gain goal passes through and eats above maintenance', () {
      final result = GoalEngine.calculate(
        request(weightKg: 60, targetWeightKg: 70, weeks: 20),
      );

      final accepted = result as GoalAccepted;
      expect(accepted.target.direction, GoalDirection.gain);
      expect(accepted.target.dailyKcal, greaterThan(accepted.target.tdee));
      // Gaining is a negative rate by convention.
      expect(accepted.target.ratePercentPerWeek, lessThan(0));
      expect(accepted.target.targetDate, isNotNull);
    });

    test('a moderate loss goal passes through unchanged', () {
      // 8 kg over 16 weeks is 0.5 kg/week against a 0.78 cap.
      final result = GoalEngine.calculate(request());

      final accepted = result as GoalAccepted;
      expect(accepted.target.direction, GoalDirection.lose);
      expect(accepted.target.ratePercentPerWeek, closeTo(0.641, 0.01));
      expect(accepted.target.dailyKcal, lessThan(accepted.target.tdee));
      expect(accepted.target.dailyKcal, greaterThan(1500));
    });
  });

  group('macros', () {
    test('protein matches the prototype at its reference profile', () {
      // The design shows 140 g for a 78 kg user; that is where 1.8 g/kg comes
      // from, so it is pinned here.
      final accepted = GoalEngine.calculate(request()) as GoalAccepted;
      expect(accepted.target.proteinG, 140);
    });

    test('the macro split accounts for the whole calorie target', () {
      final accepted = GoalEngine.calculate(request()) as GoalAccepted;
      final t = accepted.target;
      final fromMacros = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;

      // Rounding each macro to whole grams cannot drift the total far.
      expect(fromMacros, closeTo(t.dailyKcal, 10));
    });

    test('targets are round numbers, never falsely precise', () {
      final accepted = GoalEngine.calculate(request()) as GoalAccepted;
      expect(accepted.target.dailyKcal % 10, 0);
    });
  });

  group('boundaries', () {
    test('a target within half a kilo of current weight is maintenance', () {
      final result = GoalEngine.calculate(request(targetWeightKg: 77.7));
      expect((result as GoalAccepted).target.direction, GoalDirection.maintain);
    });

    test('age 18 is allowed', () {
      expect(GoalEngine.calculate(request(age: 18)), isNot(isA<GoalRefused>()));
    });

    test('a zero-week request does not divide by zero', () {
      final result = GoalEngine.calculate(request(weeks: 0));
      expect(result, isA<GoalAdjusted>());
      expect((result as GoalAdjusted).target.dailyKcal, greaterThan(0));
    });
  });
}
