/// Phase 3's acceptance criteria, exercised end to end.
///
/// Runs against the **real** `assets/db/foods.sqlite` — 11,889 foods — and a
/// throwaway in-memory diary. A mock food database would prove the repository
/// compiles; only the shipped one proves the FTS index was built, the schema
/// matches `foods.drift`, and searching for a real food finds it.
library;

import 'dart:io';

import 'package:calori/core/format.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/foods/foods_db.dart';
import 'package:calori/data/repositories/diary_repository_impl.dart';
import 'package:calori/data/repositories/food_repository_impl.dart';
import 'package:calori/domain/models/day_key.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/entry.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FoodsDb foodsDb;
  late DiaryDb diaryDb;
  late FoodRepositoryImpl foods;
  late DiaryRepositoryImpl diary;

  const dayKey = 20260826;

  setUp(() {
    final asset = File('assets/db/foods.sqlite');
    if (!asset.existsSync()) {
      fail(
        'assets/db/foods.sqlite is missing. Build it with '
        '`python tools/build_foods_db/build.py`.',
      );
    }

    foodsDb = FoodsDb.forTesting(
      NativeDatabase(asset, setup: (db) => db.execute('PRAGMA query_only = ON;')),
    );
    diaryDb = DiaryDb.forTesting(NativeDatabase.memory());

    foods = FoodRepositoryImpl(foodsDb);
    diary = DiaryRepositoryImpl(diaryDb);
  });

  tearDown(() async {
    await foodsDb.close();
    await diaryDb.close();
  });

  group('the shipped food database', () {
    test('holds the foods the build reported', () async {
      final count = await foodsDb
          .customSelect('SELECT count(*) AS n FROM foods')
          .getSingle();
      expect(count.read<int>('n'), greaterThan(11000));
    });

    test('finds staple foods by name', () async {
      for (final term in ['rice', 'chicken', 'banana', 'egg', 'pizza']) {
        final results = await foods.search(term);
        expect(results, isNotEmpty, reason: 'no results for "$term"');
      }
    });

    test('finds a South Asian dish, which is the whole point of the merge', () async {
      final results = await foods.search('biryani');
      expect(results, isNotEmpty);
      expect(
        results.first.name.toLowerCase(),
        contains('biryani'),
        reason: 'the prefix tier should put an actual biryani first',
      );
    });

    test('the prefix tier beats raw bm25 ranking', () async {
      // bm25 alone ranked "Snacks, rice cakes, brown rice, buckwheat" first for
      // "rice", because it says "rice" twice.
      final results = await foods.search('rice');
      expect(results.first.name.toLowerCase(), startsWith('rice'));
    });

    test('carries household portions, not just grams', () async {
      final results = await foods.search('milk');
      expect(
        results.any((f) => f.portions.isNotEmpty),
        isTrue,
        reason: 'no result had a household portion',
      );
    });

    test('exposes its provenance manifest for the Sources screen', () async {
      final sources = await foods.sources();
      expect(sources, isNotEmpty);
      for (final source in sources) {
        expect(source.attribution, isNotEmpty, reason: source.id);
        expect(source.licence, isNotEmpty, reason: source.id);
      }
      expect(await foods.buildVersion(), isNotNull);
    });

    group('malformed input reaches SQLite safely', () {
      // An empty FTS5 MATCH is a runtime error, and unescaped operators are a
      // syntax error. Neither may ever reach the database.
      for (final input in [
        'chick-pea "curry*',
        '*',
        '"',
        'rice OR NOT',
        '(((',
        '   ',
        '!@#\$%',
        'name:rice',
      ]) {
        test(input.isEmpty ? '(empty)' : input, () async {
          await expectLater(foods.search(input), completes);
        });
      }
    });
  });

  group('logging a day', () {
    Future<void> log(String query, {MealType meal = MealType.lunch}) async {
      final results = await foods.search(query);
      expect(results, isNotEmpty, reason: 'nothing found for "$query"');

      final food = results.first;
      final grams = food.defaultPortion?.grams ?? 100;

      await diary.addEntry(
        dayKey: dayKey,
        mealType: meal,
        source: ItemSource.db,
        items: [
          NewItem(
            name: food.name,
            grams: grams,
            macros: food.macrosFor(grams),
            source: ItemSource.db,
            portionDesc: food.defaultPortion?.label,
            foodId: food.id,
          ),
        ],
      );
    }

    test('totals are the sum of what was logged', () async {
      await log('oatmeal', meal: MealType.breakfast);
      await log('chicken', meal: MealType.lunch);
      await log('rice', meal: MealType.dinner);

      final entries = await diary.watchEntriesForDay(dayKey).first;
      expect(entries, hasLength(3));

      final expected = entries.fold(
        Macros.zero,
        (sum, entry) => sum + entry.totals,
      );

      final totals = await diary.watchTotalsForDay(dayKey).first;
      expect(totals.consumed.kcal, closeTo(expected.kcal, 0.01));
      expect(totals.consumed.proteinG, closeTo(expected.proteinG, 0.01));
      expect(totals.consumed.carbsG, closeTo(expected.carbsG, 0.01));
      expect(totals.consumed.fatG, closeTo(expected.fatG, 0.01));
      expect(totals.consumed.kcal, greaterThan(0));
    });

    test('a day with nothing logged reads as empty, not as zero progress', () async {
      final totals = await diary.watchTotalsForDay(dayKey).first;
      expect(totals.isLogged, isFalse);
      expect(totals.outcome, DayOutcomeMatcher.notLogged);
    });

    test('deleting an entry removes it from the totals', () async {
      await log('banana');
      await log('egg');

      var totals = await diary.watchTotalsForDay(dayKey).first;
      final before = totals.consumed.kcal;

      final entries = await diary.watchEntriesForDay(dayKey).first;
      await diary.deleteEntry(entries.first.id);

      totals = await diary.watchTotalsForDay(dayKey).first;
      expect(totals.consumed.kcal, lessThan(before));
      expect(
        totals.consumed.kcal,
        closeTo(before - entries.first.totals.kcal, 0.01),
      );
    });

    test('deleting the last item of an entry removes the entry too', () async {
      await log('banana');

      final entries = await diary.watchEntriesForDay(dayKey).first;
      await diary.deleteItem(entries.first.items.first.id);

      // An entry with no items would render as an empty, undismissable card.
      expect(await diary.watchEntriesForDay(dayKey).first, isEmpty);
    });

    test('editing an item changes the totals', () async {
      await log('banana');

      final entries = await diary.watchEntriesForDay(dayKey).first;
      final item = entries.first.items.first;

      await diary.updateItem(
        item.id,
        grams: item.grams * 2,
        macros: item.macros.scaled(2),
      );

      final totals = await diary.watchTotalsForDay(dayKey).first;
      expect(totals.consumed.kcal, closeTo(item.macros.kcal * 2, 0.01));
    });

    test('entries land on the day they were logged against', () async {
      await log('banana');
      expect(await diary.watchEntriesForDay(dayKey).first, hasLength(1));
      expect(
        await diary.watchEntriesForDay(DayKey.addDays(dayKey, 1)).first,
        isEmpty,
      );
    });
  });

  group('profile and targets', () {
    const profile = UserProfile(
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

    test('saving a profile replaces rather than accumulates', () async {
      await diary.saveProfile(profile);
      await diary.saveProfile(profile);

      final rows = await diaryDb.select(diaryDb.profiles).get();
      expect(rows, hasLength(1));
    });

    test('day totals are measured against the saved target', () async {
      await diary.saveProfile(profile);
      final totals = await diary.watchTotalsForDay(dayKey).first;
      expect(totals.targetKcal, 2070);
    });
  });

  group('the learned-value cache', () {
    test('remembers an accepted value and counts reuse', () async {
      const macros = Macros(kcal: 620, proteinG: 34, carbsG: 68, fatG: 22);

      await diary.rememberFood('chicken biryani', macros);
      var cached = await diary.cached('chicken biryani');
      expect(cached, isNotNull);
      expect(cached!.useCount, 1);
      expect(cached.per100g.kcal, 620);

      await diary.rememberFood('chicken biryani', macros);
      cached = await diary.cached('chicken biryani');
      expect(cached!.useCount, 2);
    });

    test('surfaces frequent foods ahead of merely recent ones', () async {
      const macros = Macros(kcal: 100, proteinG: 1, carbsG: 1, fatG: 1);

      await diary.rememberFood('daily oats', macros);
      await diary.rememberFood('daily oats', macros);
      await diary.rememberFood('daily oats', macros);
      await diary.rememberFood('one off snack', macros);

      final suggestions = await diary.suggestions();
      expect(suggestions.first.nameNormalised, 'daily oats');
    });

    test('survives deleting the entry it was learned from', () async {
      const macros = Macros(kcal: 100, proteinG: 1, carbsG: 1, fatG: 1);
      await diary.rememberFood('roti', macros);

      await diary.addEntry(
        dayKey: dayKey,
        mealType: MealType.dinner,
        source: ItemSource.db,
        items: const [
          NewItem(
            name: 'Roti',
            grams: 45,
            macros: macros,
            source: ItemSource.db,
          ),
        ],
      );

      final entries = await diary.watchEntriesForDay(dayKey).first;
      await diary.deleteEntry(entries.first.id);

      // The meal is gone; what the user taught the app about roti is not.
      expect(await diary.cached('roti'), isNotNull);
    });
  });

  group('meal type defaults', () {
    test('picks a plausible meal for the time of day', () {
      expect(mealTypeForNow(DateTime(2026, 8, 26, 8)), MealType.breakfast);
      expect(mealTypeForNow(DateTime(2026, 8, 26, 13)), MealType.lunch);
      expect(mealTypeForNow(DateTime(2026, 8, 26, 19)), MealType.dinner);
      // A 4pm bite is a snack, and food at 1am is a late snack rather than
      // tomorrow's breakfast.
      expect(mealTypeForNow(DateTime(2026, 8, 26, 16)), MealType.snack);
      expect(mealTypeForNow(DateTime(2026, 8, 26, 1)), MealType.snack);
    });
  });
}

/// Alias so the expectation reads as prose.
typedef DayOutcomeMatcher = DayOutcome;
