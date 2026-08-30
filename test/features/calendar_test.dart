/// The month grid and its summary (UC-08).
library;

import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/day_key.dart';
import 'package:calori/domain/models/entry.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:calori/features/calendar/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the month grid', () {
    test('pads to whole weeks with blanks, not neighbouring days', () {
      for (final (year, month) in [
        (2026, 1),
        (2026, 2),
        (2026, 8),
        (2024, 2), // leap year
        (2026, 11),
      ]) {
        final cells = monthGridCells(year, month);
        expect(cells.length % 7, 0, reason: '$year-$month');

        final days = cells.whereType<int>().toList();
        final expected = DateTime(year, month + 1, 0).day;
        expect(days, hasLength(expected), reason: '$year-$month');

        // Every non-blank cell belongs to this month and no other.
        for (final key in days) {
          final date = DayKey.toDate(key);
          expect(date.year, year);
          expect(date.month, month);
        }
      }
    });

    test('starts the week on Monday', () {
      // 1 August 2026 is a Saturday, so five leading blanks.
      final cells = monthGridCells(2026, 8);
      expect(cells.take(5).every((c) => c == null), isTrue);
      expect(cells[5], DayKey.of(DateTime(2026, 8, 1)));
    });

    test('a month starting on Monday has no leading blank', () {
      // 1 June 2026 is a Monday.
      final cells = monthGridCells(2026, 6);
      expect(cells.first, DayKey.of(DateTime(2026, 6, 1)));
    });
  });

  group('the month summary', () {
    late DiaryDb db;
    late ProviderContainer container;

    const profile = UserProfile(
      sex: Sex.male,
      age: 30,
      heightCm: 178,
      weightKg: 78,
      targetWeightKg: 70,
      activity: ActivityLevel.moderate,
      dailyKcal: 2000,
      dailyProteinG: 140,
      dailyCarbsG: 240,
      dailyFatG: 60,
    );

    setUp(() async {
      db = DiaryDb.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [diaryDbProvider.overrideWithValue(db)],
      );
      await container.read(diaryRepositoryProvider).saveProfile(profile);

      // Hold an open subscription for the life of the test. Reading `.future`
      // alone opens one that closes immediately, and these providers are
      // auto-dispose — so the value arrives and the provider is torn down
      // before anything derived from it can read it.
      final sub = container.listen(monthTotalsProvider, (_, _) {});
      addTearDown(sub.close);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    /// Waits for the Drift stream to re-emit after a write.
    ///
    /// `monthTotalsProvider.future` resolves with the stream's *first* value,
    /// which is the state before anything was logged. Awaiting the insert is
    /// not enough either: the query re-runs and the new value propagates a
    /// microtask later. So poll the provider until the expected number of days
    /// has arrived rather than guessing at a delay.
    Future<Map<int, DayTotals>> totalsFor(int expectedDays) async {
      for (var attempt = 0; attempt < 100; attempt++) {
        final value = container.read(monthTotalsProvider).value;
        if (value != null && value.length >= expectedDays) return value;
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      fail('month totals never reported \$expectedDays logged days');
    }

    Future<void> log(int dayKey, double kcal) {
      return container.read(diaryRepositoryProvider).addEntry(
        dayKey: dayKey,
        mealType: MealType.lunch,
        source: ItemSource.db,
        items: [
          NewItem(
            name: 'Test food',
            grams: 100,
            macros: Macros(kcal: kcal, proteinG: 30, carbsG: 40, fatG: 10),
            source: ItemSource.db,
          ),
        ],
      );
    }

    test('averages cover logged days only, not the whole month', () async {
      final now = DateTime.now();
      final first = DayKey.of(DateTime(now.year, now.month, 1));

      // Two logged days in a month that has far more days than that.
      await log(first, 2000);
      await log(DayKey.addDays(first, 1), 1000);

      await totalsFor(2);
      final summary = container.read(monthSummaryProvider);

      expect(summary.loggedDays, 2);
      // 1500, not 3000 divided by the length of the month. Dividing by the
      // month would drag every average toward zero for anyone who missed a day.
      expect(summary.avgKcal, 1500);
      expect(summary.avgProtein, 30);
    });

    test('counts days on target without counting the rest as failures', () async {
      final now = DateTime.now();
      final first = DayKey.of(DateTime(now.year, now.month, 1));

      await log(first, 1800); // under
      await log(DayKey.addDays(first, 1), 2500); // over
      await log(DayKey.addDays(first, 2), 1950); // under

      await totalsFor(3);
      final summary = container.read(monthSummaryProvider);

      expect(summary.loggedDays, 3);
      expect(summary.onTargetDays, 2);
    });

    test('an empty month reports zeroes rather than dividing by zero', () async {
      await totalsFor(0);
      final summary = container.read(monthSummaryProvider);

      expect(summary.loggedDays, 0);
      expect(summary.avgKcal, 0);
      expect(summary.avgProtein, 0);
      expect(summary.onTargetDays, 0);
    });

    test('a logged day over target is still a logged day', () async {
      final now = DateTime.now();
      final first = DayKey.of(DateTime(now.year, now.month, 1));
      await log(first, 3500);

      final totals = await totalsFor(1);
      final day = totals[first]!;

      expect(day.isLogged, isTrue);
      expect(day.isOver, isTrue);
      expect(day.outcome, DayOutcome.over);
      // Over target draws a second lap; progress is allowed past 1.
      expect(day.progress, greaterThan(1));
    });

    test('a day with no entries is notLogged, not zero progress', () async {
      final totals = await totalsFor(0);
      // Absent from the map entirely, which the grid renders as a neutral dot.
      expect(totals[DayKey.today()], isNull);
    });
  });

  group('month paging', () {
    late ProviderContainer container;

    setUp(() {
      final db = DiaryDb.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [diaryDbProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);
    });

    test('will not page past the current month', () {
      final notifier = container.read(visibleMonthProvider.notifier);
      final now = DateTime.now();

      expect(notifier.canGoForward, isFalse);
      notifier.next();
      expect(container.read(visibleMonthProvider).year, now.year);
      expect(container.read(visibleMonthProvider).month, now.month);
    });

    test('pages backwards across a year boundary', () {
      final notifier = container.read(visibleMonthProvider.notifier);
      final start = container.read(visibleMonthProvider);

      for (var i = 0; i < 13; i++) {
        notifier.previous();
      }

      final moved = container.read(visibleMonthProvider);
      final expected = DateTime(start.year, start.month - 13);
      expect(moved.year, expected.year);
      expect(moved.month, expected.month);
      expect(notifier.canGoForward, isTrue);
    });
  });
}
