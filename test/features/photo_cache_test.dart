/// The learned-value path (UC-04).
///
/// The rule this protects: a meal logged twice reports the same numbers both
/// times. Consistency beats marginal accuracy here — figures that drift between
/// two photos of the same dinner read as a bug and cost trust faster than a
/// small, stable error does.
library;

import 'package:calori/core/food_name.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DiaryDb db;
  late ProviderContainer container;
  late DiaryRepository diary;

  setUp(() {
    db = DiaryDb.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [diaryDbProvider.overrideWithValue(db)],
    );
    diary = container.read(diaryRepositoryProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('what gets remembered', () {
    test('an accepted value is stored per 100 g, not per portion', () async {
      // A 300 g plate at 600 kcal is 200 kcal/100g. Storing the portion figure
      // instead would make every future portion of this dish wrong.
      const accepted = Macros(kcal: 600, proteinG: 30, carbsG: 60, fatG: 24);
      await diary.rememberFood('chicken biryani', accepted.scaled(100 / 300));

      final cached = await diary.cached('chicken biryani');
      expect(cached!.per100g.kcal, closeTo(200, 0.01));

      // And a different portion scales from it correctly.
      expect(cached.macrosFor(150).kcal, closeTo(300, 0.01));
    });

    test('logging the same dish twice returns identical numbers', () async {
      const perHundred = Macros(kcal: 200, proteinG: 10, carbsG: 20, fatG: 8);
      await diary.rememberFood('chicken biryani', perHundred);

      final first = await diary.cached('chicken biryani');
      await diary.rememberFood('chicken biryani', perHundred);
      final second = await diary.cached('chicken biryani');

      expect(second!.per100g.kcal, first!.per100g.kcal);
      expect(second.per100g.proteinG, first.per100g.proteinG);
      expect(second.useCount, first.useCount + 1);
    });

    test('a correction replaces the earlier value', () async {
      // The cache converges on the user's corrections, not the model's first
      // guess: what is stored is what was *accepted*.
      await diary.rememberFood(
        'chicken biryani',
        const Macros(kcal: 200, proteinG: 10, carbsG: 20, fatG: 8),
      );
      await diary.rememberFood(
        'chicken biryani',
        const Macros(kcal: 260, proteinG: 12, carbsG: 22, fatG: 12),
      );

      final cached = await diary.cached('chicken biryani');
      expect(cached!.per100g.kcal, 260);
      expect(cached.useCount, 2);
    });
  });

  group('the cache key', () {
    test('matches regardless of case, punctuation or accents', () async {
      await diary.rememberFood(
        normaliseFoodName('Chicken Biryani'),
        const Macros(kcal: 200, proteinG: 10, carbsG: 20, fatG: 8),
      );

      // Every one of these is how a model might return the same dish.
      for (final variant in [
        'chicken biryani',
        'Chicken, Biryani',
        'CHICKEN BIRYANI',
        '  chicken   biryani  ',
      ]) {
        expect(
          await diary.cached(normaliseFoodName(variant)),
          isNotNull,
          reason: variant,
        );
      }
    });

    test('does not collide across genuinely different dishes', () async {
      await diary.rememberFood(
        normaliseFoodName('chicken biryani'),
        const Macros(kcal: 200, proteinG: 10, carbsG: 20, fatG: 8),
      );

      expect(await diary.cached(normaliseFoodName('chicken karahi')), isNull);
      expect(await diary.cached(normaliseFoodName('mutton biryani')), isNull);
    });
  });

  group('suggestions', () {
    test('frequency outranks recency', () async {
      const macros = Macros(kcal: 100, proteinG: 1, carbsG: 1, fatG: 1);

      for (var i = 0; i < 3; i++) {
        await diary.rememberFood('daily oats', macros);
      }
      // Logged later, but only once.
      await diary.rememberFood('one off snack', macros);

      final suggestions = await diary.suggestions();
      expect(suggestions.first.nameNormalised, 'daily oats');
    });

    test('respects the limit', () async {
      const macros = Macros(kcal: 100, proteinG: 1, carbsG: 1, fatG: 1);
      for (var i = 0; i < 12; i++) {
        await diary.rememberFood('food $i', macros);
      }
      expect(await diary.suggestions(limit: 5), hasLength(5));
    });

    test('is empty on a fresh install rather than throwing', () async {
      expect(await diary.suggestions(), isEmpty);
    });
  });

  group('what is not remembered', () {
    test('deleting the meal keeps the learned value', () async {
      const macros = Macros(kcal: 100, proteinG: 1, carbsG: 1, fatG: 1);
      await diary.rememberFood('roti', macros);

      final entryId = await diary.addEntry(
        dayKey: 20260826,
        mealType: MealType.dinner,
        source: ItemSource.ai,
        items: const [
          NewItem(
            name: 'Roti',
            grams: 45,
            macros: macros,
            source: ItemSource.ai,
            confidence: Confidence.low,
          ),
        ],
      );

      await diary.deleteEntry(entryId);

      // The meal is gone; what the user taught the app about roti is not.
      expect(await diary.cached('roti'), isNotNull);
    });

    test('an unknown food has no cached value', () async {
      expect(await diary.cached('something never logged'), isNull);
    });
  });
}
