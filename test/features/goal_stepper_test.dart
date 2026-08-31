/// The Goal screen's steppers, and the rate/weeks conversion behind them.
library;

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/core/widgets/stepper_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double value,
    required ValueChanged<double> onChanged,
    double step = 1,
    double min = 0,
    double max = 999,
    int decimals = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: StepperRow(
            label: 'Current weight',
            detail: 'kilograms',
            value: value,
            step: step,
            min: min,
            max: max,
            decimals: decimals,
            suffix: ' kg',
            onChanged: onChanged,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('stepping', () {
    testWidgets('plus and minus move by one step', (tester) async {
      final changes = <double>[];
      await pump(tester, value: 78, onChanged: changes.add);

      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));

      expect(changes, [79, 77]);
    });

    testWidgets('a fractional step does not accumulate float error', (
      tester,
    ) async {
      // 0.5 + 0.1 is 0.6000000000000001 in binary floating point, which then
      // renders as "0.6" but compares unequal to it — and after a few presses
      // starts rendering wrong too.
      var value = 0.5;
      for (var i = 0; i < 5; i++) {
        await pump(
          tester,
          value: value,
          step: 0.1,
          min: 0.1,
          max: 1.0,
          decimals: 1,
          onChanged: (v) => value = v,
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      expect(value, 1.0);
    });
  });

  group('bounds', () {
    testWidgets('will not step below the minimum', (tester) async {
      var called = false;
      await pump(
        tester,
        value: 0.1,
        step: 0.1,
        min: 0.1,
        max: 1.0,
        decimals: 1,
        onChanged: (_) => called = true,
      );

      await tester.tap(find.byIcon(Icons.remove));
      expect(called, isFalse);
    });

    testWidgets('will not step above the maximum', (tester) async {
      var called = false;
      await pump(
        tester,
        value: 1.0,
        step: 0.1,
        min: 0.1,
        max: 1.0,
        decimals: 1,
        onChanged: (_) => called = true,
      );

      await tester.tap(find.byIcon(Icons.add));
      expect(called, isFalse);
    });

    testWidgets('a disabled button is still a 44px target', (tester) async {
      await pump(tester, value: 0, min: 0, max: 10, onChanged: (_) {});

      // Disabled, not absent: a control that vanishes at the boundary makes
      // the row reflow and moves the other button under the user's thumb.
      expect(find.byIcon(Icons.remove), findsOneWidget);
      final size = tester.getSize(
        find.ancestor(
          of: find.byIcon(Icons.remove),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('display', () {
    testWidgets('shows the suffix and the right precision', (tester) async {
      await pump(tester, value: 78, onChanged: (_) {});
      expect(find.text('78 kg'), findsOneWidget);
    });

    testWidgets('one decimal for a rate', (tester) async {
      await pump(
        tester,
        value: 0.5,
        step: 0.1,
        decimals: 1,
        onChanged: (_) {},
      );
      expect(find.text('0.5 kg'), findsOneWidget);
    });
  });

  group('rate to weeks', () {
    // The Goal screen shows "% of bodyweight per week"; GoalEngine takes a
    // number of weeks. This is that conversion, kept honest here because a
    // silent drift in it moves every target date.
    int weeksFor(double weight, double target, double ratePercent) {
      final delta = (target - weight).abs();
      final weekly = weight * ratePercent / 100;
      return delta < 0.05 || weekly <= 0
          ? 12
          : (delta / weekly).ceil().clamp(1, 520);
    }

    test('78kg losing to 70kg at 0.5%/week is about 21 weeks', () {
      // 0.39 kg/week over 8 kg.
      expect(weeksFor(78, 70, 0.5), 21);
    });

    test('a faster rate takes fewer weeks', () {
      expect(weeksFor(78, 70, 1.0), lessThan(weeksFor(78, 70, 0.5)));
    });

    test('maintenance does not divide by zero', () {
      expect(weeksFor(78, 78, 0.5), 12);
    });

    test('gaining works the same way', () {
      expect(weeksFor(60, 70, 0.5), weeksFor(60, 50, 0.5));
    });

    test('never returns zero weeks', () {
      // A tiny delta at a fast rate rounds toward zero before the clamp.
      expect(weeksFor(100, 100.1, 1.0), greaterThanOrEqualTo(1));
    });
  });
}
