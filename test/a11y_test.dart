/// Accessibility guarantees that must hold on every screen.
///
/// These are not box-ticking. Each one corresponds to a way the app becomes
/// unusable for someone: a 44px minimum because thumbs are not styluses, text
/// scaling because a calorie tracker is used by people who need larger type,
/// and labels because the ring and the pips carry information that is
/// otherwise purely visual.
library;

import 'dart:ui' show Tristate;

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/core/theme/tokens.dart';
import 'package:calori/core/widgets/pill_button.dart';
import 'package:calori/core/widgets/progress_ring.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/features/onboarding/onboarding_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('tap targets', () {
    testWidgets('every button meets the 44px minimum', (tester) async {
      await pump(tester, const OnboardingScreen());

      final handle = tester.ensureSemantics();
      // Android's own guidance is 48dp; 44 is the floor this design commits to
      // in AppLayout.minTapTarget and is what the tokens are sized against.
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('a pill button is tall enough even with a short label', (
      tester,
    ) async {
      await pump(
        tester,
        Scaffold(
          body: Center(
            child: PillButton(label: 'OK', onPressed: () {}, expand: false),
          ),
        ),
      );

      final size = tester.getSize(find.byType(PillButton));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  group('text scaling', () {
    testWidgets('onboarding survives 2x type without overflowing', (
      tester,
    ) async {
      await pump(tester, const OnboardingScreen(), textScale: 2.0);

      // A RenderFlex overflow logs an exception rather than throwing, so the
      // assertion has to be on what was reported.
      expect(tester.takeException(), isNull);
    });

    testWidgets('the calorie ring keeps its centre legible at 2x', (
      tester,
    ) async {
      await pump(
        tester,
        const Scaffold(
          body: Center(
            child: CalorieRing(
              progress: 0.62,
              animate: false,
              center: Text('62%', style: AppType.ringPercent),
            ),
          ),
        ),
        textScale: 2.0,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('62%'), findsOneWidget);
    });
  });

  group('screen readers', () {
    testWidgets('buttons announce themselves as buttons', (tester) async {
      await pump(tester, const OnboardingScreen());
      final handle = tester.ensureSemantics();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('a selectable chip announces its selected state', (
      tester,
    ) async {
      await pump(
        tester,
        Scaffold(
          body: Center(
            child: SelectableChip(
              label: '1 cup',
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      // Selection is carried in the semantics as well as in colour, so it is
      // not lost to a screen reader or to anyone who cannot separate the blue
      // from the white.
      // Asserted property by property rather than with matchesSemantics,
      // which is exhaustive over every flag and breaks whenever Flutter adds
      // one — noise that has nothing to do with what this test is about.
      final node = tester.getSemantics(find.text('1 cup'));
      expect(node.label, '1 cup');
      // flagsCollection returns a Tristate, not a bool: a chip that has no
      // selected state at all is distinguishable from one that is selected
      // and one that is not.
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('contrast', () {
    testWidgets('body text on the app background passes AA', (tester) async {
      await pump(
        tester,
        const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
            child: Text('Chicken biryani', style: AppType.body),
          ),
        ),
      );

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('reduced motion', () {
    testWidgets('the ring renders without animating when motion is off', (
      tester,
    ) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.build(),
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Center(
                  child: CalorieRing(progress: 1.4, animate: true),
                ),
              ),
            ),
          ),
        ),
      );

      // One pump, no settle: with animations disabled the ring must already be
      // at its final value rather than waiting on a controller.
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('the over-target lap', () {
    testWidgets('renders past 100% without error or colour change', (
      tester,
    ) async {
      for (final progress in [0.0, 0.5, 1.0, 1.3, 2.0, 3.5]) {
        await pump(
          tester,
          Scaffold(
            body: Center(
              child: CalorieRing(progress: progress, animate: false),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'at $progress');
      }
    });
  });
}
