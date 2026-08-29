/// Onboarding, driven through the UI (UC-01, UC-02).
///
/// The goal engine is already unit-tested. What these tests check is that its
/// verdicts actually *reach the user*: a rule enforced in the domain layer and
/// then swallowed by a screen is not enforced at all.
library;

import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/features/onboarding/onboarding_screen.dart';
import 'package:calori/features/onboarding/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DiaryDb db;
  late ProviderContainer container;

  setUp(() {
    db = DiaryDb.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpFlow(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [diaryDbProvider.overrideWithValue(db)],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps something that may sit below the fold of the step's scroll view.
  ///
  /// The refusal panel pushes the alternative button past the bottom of the
  /// 800x600 test viewport, where a plain tap() lands on the scaffold behind
  /// the clipped ListView instead.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Walks to the target step with a healthy 178cm / 78kg adult.
  Future<void> reachTargetStep(
    WidgetTester tester, {
    String age = '30',
    String height = '178',
    String weight = '78',
  }) async {
    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), age);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), height);
    await tester.enterText(find.byType(TextField).at(1), weight);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  group('the under-18 stop', () {
    testWidgets('age 15 ends the flow', (tester) async {
      await pumpFlow(tester);

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '15');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Calori is built for adults'), findsOneWidget);
    });

    testWidgets('offers no way forward and no way back', (tester) async {
      await pumpFlow(tester);

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '15');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // No continue, no "I understand", no back arrow. A dead end that can be
      // reversed by tapping back and typing 19 is not a safeguard.
      expect(find.text('Continue'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(TextField), findsNothing);

      container.read(onboardingCursorProvider.notifier).back();
      await tester.pumpAndSettle();
      expect(find.text('Calori is built for adults'), findsOneWidget);
    });

    testWidgets('points to a person, not just away', (tester) async {
      await pumpFlow(tester);

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '15');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(text, contains('doctor'));
      expect(text.toLowerCase(), isNot(contains('sorry')));
    });

    testWidgets('age 18 continues', (tester) async {
      await pumpFlow(tester);

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '18');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Your height and weight'), findsOneWidget);
    });
  });

  group('unsafe targets are refused at the input', () {
    testWidgets('a target below a healthy BMI is refused inline', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      // 50 kg at 178 cm is a BMI of about 15.8.
      await tester.enterText(find.byType(TextField).first, '50');
      await tester.pumpAndSettle();

      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(text, contains('below a healthy weight'));

      // Inline, not a dialog.
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Continue is blocked while a refusal stands', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      await tester.enterText(find.byType(TextField).first, '50');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Still on the target step.
      expect(find.text('What are you aiming for?'), findsOneWidget);
    });

    testWidgets('a refusal offers a way forward, not just a wall', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      await tester.enterText(find.byType(TextField).first, '50');
      await tester.pumpAndSettle();

      expect(find.text('Maintain instead'), findsOneWidget);

      await tapVisible(tester, find.text('Maintain instead'));

      expect(find.text('How active are you?'), findsOneWidget);
      expect(container.read(onboardingProvider).targetWeightKg, 78);
    });

    testWidgets('correcting the target clears the refusal', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      await tester.enterText(find.byType(TextField).first, '50');
      await tester.pumpAndSettle();
      expect(find.text('Maintain instead'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '70');
      await tester.pumpAndSettle();

      expect(find.text('Maintain instead'), findsNothing);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How active are you?'), findsOneWidget);
    });
  });

  group('a too-fast rate corrects rather than blocks', () {
    testWidgets('shows the honest date and still allows continuing', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      // 78 -> 60 kg is 18 kg. At the 4-week minimum that is far above 1%/week.
      await tester.enterText(find.byType(TextField).first, '60');
      await tester.pumpAndSettle();

      container.read(onboardingProvider.notifier).setWeeks(4);
      await tester.pumpAndSettle();

      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(text, contains('1%'));

      // A correction is not a refusal: the flow continues.
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('How active are you?'), findsOneWidget);
    });
  });

  group('completing the flow', () {
    testWidgets('writes a profile with the engine\'s numbers', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      await tester.enterText(find.byType(TextField).first, '70');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Moderately active'));
      await tester.pumpAndSettle();

      expect(find.text('Here is your plan'), findsOneWidget);

      await tester.tap(find.text('Start tracking'));
      await tester.pumpAndSettle();

      final saved = await container.read(diaryRepositoryProvider).profile();
      expect(saved, isNotNull);
      expect(saved!.weightKg, 78);
      expect(saved.targetWeightKg, 70);
      expect(saved.dailyKcal, greaterThan(1500));
      // The prototype's reference profile: 78 kg at 1.8 g/kg.
      expect(saved.dailyProteinG, 140);
    });

    testWidgets('maintenance is a first-class path, not a fallback', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      // Target equals current weight.
      await tester.enterText(find.byType(TextField).first, '78');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Moderately active'));
      await tester.pumpAndSettle();

      expect(find.text('Here is your plan'), findsOneWidget);
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(text, contains('hold your current weight'));
    });

    testWidgets('gaining is a first-class path too', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester, weight: '60');

      await tester.enterText(find.byType(TextField).first, '70');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Moderately active'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start tracking'));
      await tester.pumpAndSettle();

      final saved = await container.read(diaryRepositoryProvider).profile();
      expect(saved, isNotNull);
      expect(saved!.targetWeightKg, greaterThan(saved.weightKg));
    });
  });

  group('tone', () {
    testWidgets('no red anywhere in the flow, including refusals', (tester) async {
      await pumpFlow(tester);
      await reachTargetStep(tester);

      await tester.enterText(find.byType(TextField).first, '50');
      await tester.pumpAndSettle();

      // Walk every rendered decoration and assert nothing reads as a warning.
      // `01-concept.md` is explicit that there is no red in this app, and a
      // refusal is exactly where a designer's hand slips.
      final containers = tester.widgetList<Container>(find.byType(Container));
      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is! BoxDecoration) continue;
        final colour = decoration.color;
        if (colour == null) continue;
        expect(
          _looksRed(colour),
          isFalse,
          reason: 'a red surface appeared on a refusal: $colour',
        );
      }
    });
  });
}

/// Whether a colour reads as a warning: clearly red-dominant and saturated.
bool _looksRed(Color colour) {
  final r = (colour.r * 255).round();
  final g = (colour.g * 255).round();
  final b = (colour.b * 255).round();
  return r > 150 && r > g * 2 && r > b * 2;
}
