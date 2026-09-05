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
    double? weeklyRateKg,
  }) => GoalRequest(
    sex: sex,
    age: age,
    heightCm: heightCm,
    weightKg: weightKg,
    targetWeightKg: targetWeightKg,
    activity: activity,
    weeks: weeks,
    weeklyRateKg: weeklyRateKg,
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


  group('a chosen rate is the rate used', () {
    /// The Goal screen sets a rate; onboarding sets a timeframe.
    ///
    /// The rate used to be converted into whole weeks and divided back out by
    /// the engine, which quantised it. At 95 kg aiming for 92 kg at 1%/week,
    /// `ceil(3 / 0.95)` took 3.16 weeks to 4 and the rate came back as
    /// 0.75 kg/week — a target 220 kcal above what the user actually chose.
    test('the target follows the rate, not a rounded number of weeks', () {
      for (final weightKg in [55.0, 62.0, 78.0, 95.0]) {
        for (final percent in [0.2, 0.3, 0.5, 0.7, 1.0]) {
          for (final drop in [3.0, 8.0, 15.0]) {
            final weekly = weightKg * percent / 100;
            final result = GoalEngine.calculate(
              request(
                weightKg: weightKg,
                targetWeightKg: weightKg - drop,
                // The quantised figure the screen still sends for the "you
                // asked for this date" comparison. It must not drive the rate.
                weeks: (drop / weekly).ceil(),
                weeklyRateKg: weekly,
              ),
            );

            final target = switch (result) {
              GoalAccepted(:final target) => target,
              GoalAdjusted(:final target) => target,
              GoalRefused() => null,
            };
            if (target == null) continue;

            final where = '$weightKg kg, $percent%/week, -$drop kg';

            expect(
              target.ratePercentPerWeek,
              closeTo(percent, 0.0001),
              reason: 'the rate came back changed at $where',
            );

            final expected =
                ((target.tdee - weekly * GoalEngine.kcalPerKg / 7) / 10)
                    .round() *
                10;

            // Below the floor the engine deliberately clamps, which is its own
            // tested behaviour and not what this is about.
            if (expected < Sex.male.calorieFloor) continue;

            expect(
              target.dailyKcal,
              expected,
              reason: 'the target does not match the chosen rate at $where',
            );
          }
        }
      }
    });

    test('the worst case from the bug report', () {
      // 95 kg -> 92 kg at 1%/week. Shown 1360, should be 1140.
      const weekly = 0.95;
      final target =
          (GoalEngine.calculate(
                    request(
                      weightKg: 95,
                      targetWeightKg: 92,
                      weeks: 4,
                      weeklyRateKg: weekly,
                    ),
                  )
                  as GoalAccepted)
              .target;

      expect(
        target.dailyKcal,
        ((target.tdee - weekly * GoalEngine.kcalPerKg / 7) / 10).round() * 10,
      );
    });

    test('without a rate the timeframe still decides, as onboarding needs', () {
      // The old path, unchanged: no weeklyRateKg means the rate comes from the
      // number of weeks, which is what the onboarding slider asks for.
      final target =
          (GoalEngine.calculate(request(weeks: 16)) as GoalAccepted).target;

      expect(target.dailyKcal, 2160);
      expect(target.proteinG, 140);
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

  group('the macro split adds up', () {
    /// Swept across every profile the engine can be handed.
    ///
    /// The bug this guards: protein and fat both scale with bodyweight while
    /// the target is capped from below by the calorie floor, so at a high
    /// weight and a low target the two alone exceeded the whole budget — and
    /// `carbs` clamping to zero swallowed the evidence. The goal card then
    /// printed three macros summing to more than the calorie figure directly
    /// above them.
    test('protein, carbs and fat never exceed the calorie target', () {
      for (final sex in Sex.values) {
        for (final activity in ActivityLevel.values) {
          for (var weightKg = 45.0; weightKg <= 180; weightKg += 5) {
            for (var heightCm = 150.0; heightCm <= 200; heightCm += 10) {
              for (final age in [18, 30, 55, 80]) {
                final result = GoalEngine.calculate(
                  request(
                    sex: sex,
                    age: age,
                    activity: activity,
                    weightKg: weightKg,
                    heightCm: heightCm,
                    // Deliberately ambitious, so the rate cap and the calorie
                    // floor both get their chance to bind.
                    targetWeightKg: weightKg * 0.7,
                    weeks: 8,
                  ),
                );

                final target = switch (result) {
                  GoalAccepted(:final target) => target,
                  GoalAdjusted(:final target) => target,
                  GoalRefused() => null,
                };
                if (target == null) continue;

                final macroKcal =
                    target.proteinG * 4 + target.carbsG * 4 + target.fatG * 9;

                // Five kcal of slack: the three are whole grams, and rounding
                // carbs to the nearest one can cost two.
                expect(
                  macroKcal,
                  lessThanOrEqualTo(target.dailyKcal + 5),
                  reason:
                      '$sex, $age y, $weightKg kg, $heightCm cm, $activity: '
                      '${target.proteinG} P, ${target.carbsG} C, '
                      '${target.fatG} F = $macroKcal kcal against a '
                      '${target.dailyKcal} kcal target',
                );

                expect(target.proteinG, greaterThan(0));
                expect(target.carbsG, greaterThanOrEqualTo(0));
                expect(target.fatG, greaterThan(0));
              }
            }
          }
        }
      }
    });

    test('the reference profile is untouched by the reconciliation', () {
      // The prototype's own figures. Fitting the macros inside the target must
      // not move anything here; if it does, it has reached past the cases it
      // exists for.
      final target = (GoalEngine.calculate(request()) as GoalAccepted).target;
      expect(target.dailyKcal, 2160);
      expect(target.proteinG, 140);
      expect(target.carbsG, 265);
      expect(target.fatG, 60);
    });
  });

  group('projected dates', () {
    test('a near-zero rate does not project a date centuries out', () {
      // A TDEE barely above the calorie floor leaves almost nothing for a
      // deficit, so totalChange / rate ran away — and _formatDate rendered the
      // result as a perfectly cheerful "12 March".
      for (var weightKg = 46.0; weightKg <= 70; weightKg += 2) {
        final result = GoalEngine.calculate(
          request(
            sex: Sex.female,
            age: 80,
            heightCm: 150,
            weightKg: weightKg,
            targetWeightKg: weightKg - 1,
            activity: ActivityLevel.sedentary,
            weeks: 1,
          ),
        );

        final target = switch (result) {
          GoalAccepted(:final target) => target,
          GoalAdjusted(:final target) => target,
          GoalRefused() => null,
        };

        final date = target?.targetDate;
        if (date == null) continue;

        expect(
          date.difference(today).inDays,
          lessThanOrEqualTo((GoalEngine.maxProjectionWeeks * 7).ceil()),
          reason: 'at $weightKg kg the target date landed on $date',
        );
      }
    });
  });
}
