/// Setting the calorie and protein goals by hand (UC-10).
///
/// The requirement was blunt: *"the user should have option to manually edit
/// their protien and calorie goals too, we dont want to restrict them on what
/// we think is right."* So these check three things the feature is worthless
/// without — that a hand-set number is saved, that it survives the engine
/// running again on the next stepper press, and that a figure the engine would
/// refuse outright is still honoured.
library;

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:calori/features/goal/goal_screen.dart';
import 'package:calori/features/home/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _profile = UserProfile(
  sex: Sex.male,
  age: 30,
  heightCm: 178,
  weightKg: 78,
  targetWeightKg: 70,
  activity: ActivityLevel.moderate,
  dailyKcal: 2070,
  dailyProteinG: 140,
  dailyCarbsG: 247,
  dailyFatG: 58,
);

void main() {
  late DiaryDb db;
  late ProviderContainer container;

  setUp(() {
    db = DiaryDb.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [diaryDbProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  UserProfile? saved() => container.read(profileProvider).value;

  /// Spins the real event loop until [ready], then rebuilds.
  ///
  /// Drift writes do not complete inside the fake-async zone `testWidgets`
  /// runs in, so anything that waits on one has to do it in `runAsync`.
  Future<void> waitFor(
    WidgetTester tester,
    bool Function() ready,
    String describe,
  ) async {
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 300; attempt++) {
        if (ready()) return;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail(describe);
    });
    await tester.pump();
  }

  Future<void> pumpGoal(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await container.read(diaryRepositoryProvider).saveProfile(_profile);
      final sub = container.listen(profileProvider, (_, _) {});
      addTearDown(sub.close);
      for (var attempt = 0; attempt < 300; attempt++) {
        if (saved() != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.build(), home: const GoalScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the sheet behind [target], types [value], and saves.
  Future<void> setByHand(
    WidgetTester tester,
    Finder target,
    String value,
  ) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, value);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The write is debounced, so the timer has to be allowed to fire.
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a hand-set calorie goal is saved and takes effect', (
    tester,
  ) async {
    await pumpGoal(tester);
    expect(find.text('2,070'), findsOneWidget);

    await setByHand(tester, find.text('2,070'), '2400');
    await waitFor(tester, () => saved()?.kcalOverride == 2400, 'never saved');

    final profile = saved()!;
    expect(profile.kcalOverride, 2400);
    // Mirrored into the plain figure, so the ring and the day totals follow
    // without knowing overrides exist.
    expect(profile.dailyKcal, 2400);
    expect(profile.hasManualGoals, isTrue);

    // Carbs and fat re-derive, so the three still fit inside the new total.
    expect(
      profile.dailyProteinG * 4 +
          profile.dailyCarbsG * 4 +
          profile.dailyFatG * 9,
      lessThanOrEqualTo(2405),
    );
  });

  testWidgets('the engine says what it would have said, and can be restored', (
    tester,
  ) async {
    await pumpGoal(tester);
    await setByHand(tester, find.text('2,070'), '2400');
    await waitFor(tester, () => saved()?.kcalOverride == 2400, 'never saved');

    // Overruling the engine must not hide it.
    expect(find.textContaining('Calori suggests'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await waitFor(tester, () => saved()?.kcalOverride == null, 'never cleared');

    expect(saved()!.kcalOverride, isNull);
    expect(saved()!.hasManualGoals, isFalse);
  });

  testWidgets('an override survives the engine running again', (tester) async {
    await pumpGoal(tester);
    await setByHand(tester, find.text('2,070'), '2400');
    await waitFor(tester, () => saved()?.kcalOverride == 2400, 'never saved');

    // The bug this guards: _commit recalculates on every stepper press, so an
    // override that is not carried through is silently overwritten by the
    // engine the moment the user nudges their weight.
    final weightStepper = find.byIcon(Icons.add).first;
    await tester.ensureVisible(weightStepper);
    await tester.pumpAndSettle();
    await tester.tap(weightStepper);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await waitFor(tester, () => saved()!.weightKg == 79, 'the weight never saved');

    expect(saved()!.kcalOverride, 2400, reason: 'the engine clobbered it');
    expect(saved()!.dailyKcal, 2400);
  });

  testWidgets('a goal the engine would refuse is still honoured', (
    tester,
  ) async {
    await pumpGoal(tester);

    // 800 kcal is below the 1500 floor for a man, which the engine will not
    // suggest. The user asked not to be restricted by what the app thinks is
    // right, so it is saved — with the app's opinion stated once, underneath.
    await setByHand(tester, find.text('2,070'), '800');
    await waitFor(tester, () => saved()?.kcalOverride == 800, 'never saved');

    expect(saved()!.dailyKcal, 800);
    expect(find.textContaining('below the 1500 kcal'), findsOneWidget);
  });
}
