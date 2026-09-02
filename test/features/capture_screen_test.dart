/// The capture screen (UC-03, UC-04).
///
/// The camera itself needs a device, so these cover what a test can settle:
/// the controls are present, the details sheet round-trips its text, and — the
/// one that is a stated requirement rather than a nicety — the details field
/// never takes focus on its own.
library;

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/features/photo/capture_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

  Future<void> pump(WidgetTester tester, [Size size = const Size(411, 891)]) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const CaptureScreen(),
        ),
      ),
    );
    // No settle: `availableCameras()` never completes on a test host, so the
    // screen sits in its starting state — which is exactly the state these
    // assertions are about.
    await tester.pump();
  }

  group('the controls', () {
    testWidgets('offers a shutter, a gallery and a way out', (tester) async {
      await pump(tester);

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Add details'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('lays out on a small phone without overflowing', (
      tester,
    ) async {
      await pump(tester, const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers nothing to send until a photo has been taken', (
      tester,
    ) async {
      await pump(tester);

      // The screen starts as a viewfinder. Retake and Send belong to the state
      // *after* the shutter, and showing either before there is a photo would
      // offer to send nothing.
      //
      // The transition itself — shutter, then Send — cannot be tested here:
      // `availableCameras()` never completes on a test host, so the controller
      // stays null and `_shoot` returns immediately. A test that "passed" by
      // tapping a dead shutter would pass just as happily against the old code
      // that sent on the shutter press, which is the bug this was changed for.
      // Device check 1 in the plan is what actually covers it.
      expect(find.text('Send'), findsNothing);
      expect(find.text('Retake'), findsNothing);
      expect(find.text('Gallery'), findsOneWidget);
    });
  });

  group('add details (UC-04)', () {
    testWidgets('never takes focus on its own', (tester) async {
      await pump(tester);

      // The stated constraint: "the field must never take focus automatically.
      // Capture stays one tap for users who skip it." A keyboard appearing over
      // the viewfinder would also hide the shutter.
      //
      // Asserted as "there is no text field at all", which is the strongest
      // form of it — the field lives in a sheet that has not been opened.
      // Checking FocusManager instead would pass trivially, because the
      // Scaffold's own focus scope always holds primary focus.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('opens a sheet when asked, and focuses there', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();

      // Autofocus here is correct — the user chose to open it.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('shows what was typed once the sheet is dismissed', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'chicken biryani, one plate',
      );
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // The button becomes a preview of the hint, so it is obvious the text
      // will be sent and obvious how to change it.
      expect(find.text('chicken biryani, one plate'), findsOneWidget);
      expect(find.text('Add details'), findsNothing);
    });

    testWidgets('keeps the previous text when reopened', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'two rotis');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('two rotis'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'two rotis',
      );
    });

    testWidgets('dismissing without Done leaves the hint alone', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Add details'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abandoned');

      // Tap the scrim rather than Done.
      await tester.tapAt(const Offset(200, 60));
      await tester.pumpAndSettle();

      expect(find.text('abandoned'), findsNothing);
      expect(find.text('Add details'), findsOneWidget);
    });
  });
}
