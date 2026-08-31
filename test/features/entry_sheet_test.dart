/// Editing a logged meal (UC-09).
///
/// Before this the sheet was read-only, so fixing one wrong portion meant
/// deleting the whole meal. These check that a correction is possible, that it
/// lands in the database, and that the totals follow.
library;

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/entry.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:calori/features/home/providers.dart';
import 'package:calori/features/home/widgets/entry_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DiaryDb db;
  late ProviderContainer container;
  late int entryId;

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

  /// Seeds a meal and pumps the sheet.
  ///
  /// All database work runs inside [WidgetTester.runAsync]. `testWidgets` puts
  /// its body — and its `setUp` — inside a fake-async zone where real timers
  /// never fire, so a Drift stream awaited there deadlocks the whole test with
  /// no output at all. That is not obvious from the symptom, which is why this
  /// is here rather than in setUp.
  Future<void> seedAndPump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final diary = container.read(diaryRepositoryProvider);
      entryId = await diary.addEntry(
        dayKey: container.read(selectedDayProvider),
        mealType: MealType.snack,
        source: ItemSource.ai,
        items: const [
          NewItem(
            name: 'chicken biryani',
            grams: 300,
            macros: Macros(kcal: 620, proteinG: 28, carbsG: 72, fatG: 24),
            source: ItemSource.ai,
            confidence: Confidence.medium,
          ),
          NewItem(
            name: 'raita',
            grams: 100,
            macros: Macros(kcal: 60, proteinG: 3, carbsG: 5, fatG: 3),
            source: ItemSource.ai,
          ),
        ],
      );

      final sub = container.listen(entriesForSelectedDayProvider, (_, _) {});
      addTearDown(sub.close);
      await _waitFor(container, (e) => e.any((x) => x.id == entryId));
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(body: EntrySheet(entryId: entryId)),
        ),
      ),
    );
    await tester.pump();
  }

  /// Taps, then waits for the *changed* state to come back round the stream.
  ///
  /// [settled] must describe the state after the write. Waiting merely for the
  /// entry to exist would return immediately with the value from before the
  /// tap, and every assertion would check the old data.
  Future<LoggedEntry> tapAndWait(
    WidgetTester tester,
    Finder target,
    bool Function(LoggedEntry) settled,
  ) async {
    // Scrolled into view first: the sheet is a DraggableScrollableSheet and the
    // per-item chips sit below its fold, where a plain tap lands on whatever is
    // behind the clipped viewport and silently does nothing.
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pump();

    late LoggedEntry entry;
    await tester.runAsync(() async {
      final entries = await _waitFor(
        container,
        (list) => list.any((e) => e.id == entryId && settled(e)),
      );
      entry = entries.firstWhere((e) => e.id == entryId);
    });
    await tester.pump();
    return entry;
  }

  group('what the sheet shows', () {
    testWidgets('lists every item with its amount', (tester) async {
      await seedAndPump(tester);

      expect(find.text('chicken biryani'), findsOneWidget);
      expect(find.text('raita'), findsOneWidget);
      expect(find.text('300 g · 620 kcal'), findsOneWidget);
    });

    testWidgets('shows the meal total', (tester) async {
      await seedAndPump(tester);
      expect(find.text('680 kcal'), findsOneWidget);
    });

    testWidgets('marks the current meal type', (tester) async {
      await seedAndPump(tester);
      // Logged as a snack in setUp; every meal is offered so it can be moved.
      expect(find.text('Snack'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });
  });

  group('correcting a portion', () {
    testWidgets('doubling an item doubles its macros', (tester) async {
      await seedAndPump(tester);

      // The first item's 2x chip. Both items carry the same chips, so index by
      // position rather than by label alone.
      final entry = await tapAndWait(
        tester,
        find.text('2×').first,
        (e) => e.items.any((i) => i.grams == 600),
      );
      final item = entry.items.firstWhere((i) => i.name == 'chicken biryani');
      expect(item.grams, 600);
      expect(item.macros.kcal, 1240);
    });

    testWidgets('halving after doubling returns to the original', (
      tester,
    ) async {
      await seedAndPump(tester);

      await tapAndWait(
        tester,
        find.text('2×').first,
        (e) => e.items.any((i) => i.grams == 600),
      );
      final entry = await tapAndWait(
        tester,
        find.text('0.5×').first,
        (e) => e.items.any((i) => i.grams == 300),
      );

      // Rescaling is relative to what is stored, so adjustments do not
      // compound into somewhere unrecoverable.
      final item = entry.items.firstWhere((i) => i.name == 'chicken biryani');
      expect(item.grams, 300);
      expect(item.macros.kcal, 620);
    });
  });

  group('removing things', () {
    testWidgets('removing one item leaves the rest of the meal', (
      tester,
    ) async {
      await seedAndPump(tester);

      final entry = await tapAndWait(
        tester,
        find.byIcon(Icons.close).first,
        (e) => e.items.length == 1,
      );
      expect(entry.items, hasLength(1));
      expect(entry.items.single.name, 'raita');
    });
  });

  group('moving a meal', () {
    testWidgets('changing the meal type writes through', (tester) async {
      await seedAndPump(tester);

      // The commonest correction after a portion: something logged at 4pm
      // lands in "snack" by default and was actually lunch.
      final entry = await tapAndWait(
        tester,
        find.text('Lunch'),
        (e) => e.mealType == MealType.lunch,
      );
      expect(entry.mealType, MealType.lunch);
    });
  });
}

/// Waits until the day's stream satisfies [ready], and returns it.
Future<List<LoggedEntry>> _waitFor(
  ProviderContainer container,
  bool Function(List<LoggedEntry>) ready,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final entries = container.read(entriesForSelectedDayProvider).value;
    if (entries != null && ready(entries)) return entries;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw StateError('the day stream never reached the expected state');
}
