/// Every screen renders at phone size without overflowing.
///
/// Cheaper and far more reliable than driving an emulator: a RenderFlex
/// overflow reports itself as an exception, so pumping each screen at a real
/// phone's dimensions catches the class of bug that "looks fine on my
/// 800x600 test surface" hides.
///
/// The sizes below are deliberate. 411x891 is a common Android logical
/// viewport; 320x568 is about the smallest phone still in use, and is where
/// fixed widths and long labels break first.
library;

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:calori/features/calendar/calendar_screen.dart';
import 'package:calori/features/goal/goal_screen.dart';
import 'package:calori/features/home/home_screen.dart';
import 'package:calori/features/shell/app_shell.dart';
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

  setUp(() async {
    db = DiaryDb.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [diaryDbProvider.overrideWithValue(db)],
    );
    await container.read(diaryRepositoryProvider).saveProfile(_profile);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen,
    Size size,
  ) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.build(), home: screen),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  const phone = Size(411, 891);
  const small = Size(320, 568);

  group('no screen overflows', () {
    for (final (name, size) in [('a normal phone', phone), ('a small phone', small)]) {
      testWidgets('Home on $name', (tester) async {
        await pumpAt(tester, const HomeScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Calendar on $name', (tester) async {
        await pumpAt(tester, const CalendarScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Goal on $name', (tester) async {
        await pumpAt(tester, const GoalScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the whole shell on $name', (tester) async {
        await pumpAt(tester, const AppShell(), size);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the nav bar', () {
    testWidgets('offers two tabs and a camera, not three tabs', (tester) async {
      await pumpAt(tester, const AppShell(), phone);

      // Calendar is reached from the date strip, not the nav. Ui/ shows
      // Home | camera | Goal, and a third tab here would be the bug I already
      // shipped once.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Calendar'), findsNothing);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });

    testWidgets('only the active tab shows its label', (tester) async {
      await pumpAt(tester, const AppShell(), phone);

      // Home is active by default, so "Goal" is an icon only until selected.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Goal'), findsNothing);
    });
  });

  group('the Goal screen', () {
    testWidgets('edits in place with steppers', (tester) async {
      await pumpAt(tester, const GoalScreen(), phone);

      expect(find.text('Current weight'), findsOneWidget);
      expect(find.text('Goal weight'), findsOneWidget);
      expect(find.text('Rate of loss'), findsOneWidget);

      // Three steppers, so three of each button. No "Change goal" button
      // pushing to a second screen.
      expect(find.byIcon(Icons.add), findsNWidgets(3));
      expect(find.byIcon(Icons.remove), findsNWidgets(3));
      expect(find.text('Change goal'), findsNothing);
    });

    testWidgets('shows the stored target', (tester) async {
      await pumpAt(tester, const GoalScreen(), phone);
      expect(find.text('2,070'), findsOneWidget);
      expect(find.text('78 kg'), findsOneWidget);
      expect(find.text('70 kg'), findsOneWidget);
    });
  });

  group('the Calendar', () {
    testWidgets('explains what its rings mean', (tester) async {
      await pumpAt(tester, const CalendarScreen(), phone);

      // Three states, only two of which are a ring. Without the key, a grey
      // ring and a small dot are indistinguishable guesses.
      expect(find.text('on target'), findsOneWidget);
      expect(find.text('over'), findsOneWidget);
      expect(find.text('not logged'), findsOneWidget);
    });

    testWidgets('summarises with an average and a count', (tester) async {
      // Needs a logged day: with none, the card correctly shows its empty
      // state instead, which is a different assertion.
      final now = DateTime.now();
      await container.read(diaryRepositoryProvider).addEntry(
        dayKey: now.year * 10000 + now.month * 100 + now.day,
        mealType: MealType.lunch,
        source: ItemSource.db,
        items: const [
          NewItem(
            name: 'Test food',
            grams: 100,
            macros: Macros(kcal: 500, proteinG: 30, carbsG: 50, fatG: 15),
            source: ItemSource.db,
          ),
        ],
      );

      await pumpAt(tester, const CalendarScreen(), phone);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('AVERAGE'), findsOneWidget);
      expect(find.text('LOGGED'), findsOneWidget);
      // The qualifier is the point: dividing by the whole month would drag
      // every average toward zero for anyone who missed a day.
      expect(find.text('kcal per logged day'), findsOneWidget);
    });
  });
}
