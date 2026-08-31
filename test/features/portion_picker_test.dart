/// The serving and the count are two separate questions (UC-05).
///
/// They used to be two unlabelled rows of chips that both named the portion —
/// "1 cup" directly above "2 × 1 cup" — so it was unreadable which row set the
/// serving and which set how many of it. These check the split holds and that
/// the count actually reaches the database.
///
/// Runs against the real `assets/db/foods.sqlite`: the thing under test is a
/// portion picker, and a food with no household measures would prove nothing.
library;

import 'dart:io';

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/core/widgets/stepper_row.dart';
import 'package:calori/data/diary/diary_db.dart';
// Drift generates its own `Food` row class; the domain model is the one
// this test means.
import 'package:calori/data/foods/foods_db.dart' hide Food;
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/features/search/providers.dart';
import 'package:calori/features/search/search_screen.dart';
import 'package:calori/features/search/widgets/food_result_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _dayKey = 20260831;

void main() {
  late DiaryDb diaryDb;
  late FoodsDb foodsDb;
  late ProviderContainer container;

  setUp(() {
    final asset = File('assets/db/foods.sqlite');
    if (!asset.existsSync()) {
      fail(
        'assets/db/foods.sqlite is missing. Build it with '
        '`python tools/build_foods_db/build.py`.',
      );
    }

    diaryDb = DiaryDb.forTesting(NativeDatabase.memory());
    foodsDb = FoodsDb.forTesting(
      NativeDatabase(asset, setup: (db) => db.execute('PRAGMA query_only = ON;')),
    );

    container = ProviderContainer(
      overrides: [
        diaryDbProvider.overrideWithValue(diaryDb),
        foodsDbProvider.overrideWithValue(foodsDb),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await foodsDb.close();
    await diaryDb.close();
  });

  /// Pumps the search screen with `query` run and the first result expanded,
  /// and hands back the food that result came from.
  Future<Food> pumpExpanded(WidgetTester tester, String query) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const SearchScreen(dayKey: _dayKey),
        ),
      ),
    );
    await tester.pump();

    container.read(searchQueryProvider.notifier).set(query);

    // Real event loop: the search debounces on a timer and then hits SQLite,
    // neither of which advances inside the fake-async zone testWidgets runs in.
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 300; attempt++) {
        if (container.read(searchResultsProvider).value?.isNotEmpty ?? false) {
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('the search never returned results for "$query"');
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FoodResultCard).first);
    await tester.pumpAndSettle();

    return container.read(searchResultsProvider).value!.first;
  }

  testWidgets('the serving and the count are labelled separately', (
    tester,
  ) async {
    await pumpExpanded(tester, 'milk');

    expect(find.text('SERVING'), findsOneWidget);
    expect(find.text('HOW MANY'), findsOneWidget);

    // The old picker offered "2 × 1 cup" as a chip, which is the ambiguity
    // this replaced: the multiplier belongs to the counter, not the serving.
    expect(find.textContaining('×'), findsNothing);
  });

  testWidgets('a food with no household measure still names its serving', (
    tester,
  ) async {
    // 100 g used to be an invisible default that the multiplier chips silently
    // scaled. Whatever the count multiplies has to be on screen.
    final food = await pumpExpanded(tester, 'cornstarch');

    if (food.portions.isEmpty) {
      expect(find.text('100 g'), findsWidgets);
    }
  });

  testWidgets('stepping the count scales the grams and what is saved', (
    tester,
  ) async {
    final food = await pumpExpanded(tester, 'milk');
    final serving = food.defaultPortion?.grams ?? 100;

    // 1 -> 1.5 -> 2. Half steps, because half a serving is a real portion.
    await tester.ensureVisible(find.byIcon(Icons.add).first);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    await tester.ensureVisible(find.byIcon(Icons.add).first);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 2.0);
    expect(find.text('${(serving * 2).round()} g'), findsWidgets);

    final save = find.text('Add to log');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 300; attempt++) {
        final entries = await container
            .read(diaryRepositoryProvider)
            .watchEntriesForDay(_dayKey)
            .first;
        if (entries.isNotEmpty) {
          expect(entries.single.items.single.grams, closeTo(serving * 2, 0.01));
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('the entry was never written');
    });
  });
}
