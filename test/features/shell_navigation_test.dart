/// Two navigation bugs the emulator never showed and a real device did.
///
/// Both come from the same root: `SearchScreen` is a **shell destination**, not
/// a pushed route, and an `IndexedStack` builds every destination at launch.
/// Code written for the pushed case — an unconditional `Navigator.pop()`, an
/// `autofocus` field — behaves completely differently there.
///
/// Runs against the real `assets/db/foods.sqlite`, because the flow under test
/// is "search for a food and log it" and a mock would prove nothing about it.
library;

import 'dart:io';

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/foods/foods_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/repositories/diary_repository.dart';
import 'package:calori/features/home/providers.dart';
import 'package:calori/features/search/providers.dart';
import 'package:calori/features/search/widgets/food_result_card.dart';
import 'package:calori/features/shell/app_shell.dart';
import 'package:calori/features/shell/providers.dart';
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

  /// Pumps the whole shell at a common phone size.
  ///
  /// The profile is saved inside [WidgetTester.runAsync]: `testWidgets` runs
  /// its body in a fake-async zone where real timers never fire, and awaiting
  /// Drift there can hang the test with no output at all.
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await container.read(diaryRepositoryProvider).saveProfile(_profile);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.build(), home: const AppShell()),
      ),
    );
    await tester.pump();
  }

  /// Spins the real event loop until [ready], or fails.
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
    await tester.pumpAndSettle();
  }

  testWidgets('opening the app does not raise the keyboard over Home', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.pump();

    // The search field used to carry `autofocus: true`. IndexedStack builds it
    // at launch even though Home is showing, so it took focus while offstage
    // and the keyboard slid up over the ring on a cold start.
    final focused = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where((field) => field.focusNode.hasFocus);

    expect(focused, isEmpty, reason: 'a field took focus while offstage');
  });

  testWidgets('logging a food by hand returns to Home, not a black screen', (
    tester,
  ) async {
    await pumpShell(tester);

    // What Home's `+` does. A shell destination, so nothing is pushed and the
    // Navigator still holds exactly one route: the one containing AppShell.
    container
        .read(shellScreenControllerProvider.notifier)
        .go(ShellScreen.search);
    await tester.pumpAndSettle();

    container.read(searchQueryProvider.notifier).set('banana');
    await waitFor(
      tester,
      () => container.read(searchResultsProvider).value?.isNotEmpty ?? false,
      'the search never returned results for "banana"',
    );

    // Collapsed, a result card is just its header, so tapping the card expands
    // it into the portion picker.
    await tester.tap(find.byType(FoodResultCard).first);
    await tester.pumpAndSettle();

    final save = find.text('Add to log');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();

    await waitFor(
      tester,
      () => container.read(shellScreenControllerProvider) == ShellScreen.home,
      'saving never returned the shell to Home',
    );

    // The bug: `_save` ended with an unconditional `navigator.pop()`. With
    // nothing pushed above it, that popped the app's only route and left an
    // empty Navigator painting black until the process was restarted.
    expect(find.byType(AppShell), findsOneWidget);
    expect(container.read(shellScreenControllerProvider), ShellScreen.home);

    // And the food actually landed, which is the point of the screen. Read
    // inside runAsync: awaiting a Drift stream in the fake-async zone hangs.
    await tester.runAsync(() async {
      final entries = await container
          .read(diaryRepositoryProvider)
          .watchEntriesForDay(container.read(selectedDayProvider))
          .first;
      expect(entries, hasLength(1));
    });
  });

  testWidgets('a result card is usable again after logging from it', (
    tester,
  ) async {
    await pumpShell(tester);

    container
        .read(shellScreenControllerProvider.notifier)
        .go(ShellScreen.search);
    await tester.pumpAndSettle();

    container.read(searchQueryProvider.notifier).set('banana');
    await waitFor(
      tester,
      () => container.read(searchResultsProvider).value?.isNotEmpty ?? false,
      'the search never returned results for "banana"',
    );

    Future<void> logFirstResult() async {
      // Scrolled into view first. Saving scrolls the list to reach the button,
      // and the shell's IndexedStack keeps that scroll position — so on the
      // second pass the first card sits above the viewport and a tap on its
      // centre lands somewhere else entirely.
      final card = find.byType(FoodResultCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();

      await tester.tap(card);
      await tester.pumpAndSettle();

      final save = find.text('Add to log');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
    }

    await logFirstResult();
    await waitFor(
      tester,
      () => container.read(shellScreenControllerProvider) == ShellScreen.home,
      'the first save never returned the shell to Home',
    );

    // Back to search. The card was never disposed — SearchScreen lives in the
    // shell's IndexedStack — so a `_saving` flag left true survived here,
    // showing "Saving…" forever and refusing every later attempt at the guard
    // on the way in. Only the shell-destination path was affected, because
    // popping a pushed route disposes the card and hides it.
    container
        .read(shellScreenControllerProvider.notifier)
        .go(ShellScreen.search);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(FoodResultCard).first);
    await tester.pumpAndSettle();

    expect(
      find.text('Saving…'),
      findsNothing,
      reason: 'the card is still stuck in its saving state',
    );

    await logFirstResult();
    await waitFor(
      tester,
      () => container.read(shellScreenControllerProvider) == ShellScreen.home,
      'the card refused to save a second time',
    );

    await tester.runAsync(() async {
      final entries = await container
          .read(diaryRepositoryProvider)
          .watchEntriesForDay(container.read(selectedDayProvider))
          .first;
      expect(entries, hasLength(2), reason: 'the second log did not land');
    });
  });
}
