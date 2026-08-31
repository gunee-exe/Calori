/// The photo review screen, and the states it can be in.
///
/// The no-food case is why this file exists. A photograph of a hand came back
/// as a 500 kcal entry: the model said it was not food, and the app logged it
/// anyway. Nothing here may make that possible again.
library;

import 'dart:io';

import 'package:calori/core/theme/app_theme.dart';
import 'package:calori/data/ai/vision_service.dart';
import 'package:calori/data/diary/diary_db.dart';
import 'package:calori/data/providers.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/food.dart';
import 'package:calori/features/photo/providers.dart';
import 'package:calori/features/photo/review_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DiaryDb db;
  late ProviderContainer container;
  late File photo;

  setUp(() {
    db = DiaryDb.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [diaryDbProvider.overrideWithValue(db)],
    );

    // A real file, because the screen renders it with Image.file.
    photo = File(
      '${Directory.systemTemp.path}/calori-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
    )..writeAsBytesSync(_onePixelJpeg);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    if (photo.existsSync()) photo.deleteSync();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.build(),
          home: ReviewScreen(photo: photo, dayKey: 20260831),
        ),
      ),
    );
    await tester.pump();
  }

  void setItems(List<ProposedItem> items) {
    container.read(photoAnalysisProvider.notifier).state = AsyncData(items);
  }

  group('when the photo has no food in it', () {
    testWidgets('says so plainly', (tester) async {
      setItems(const []);
      await pump(tester);

      expect(find.text('No food in that photo'), findsOneWidget);
    });

    testWidgets('offers no way to save', (tester) async {
      setItems(const []);
      await pump(tester);

      // The whole bug in one assertion. If a Save button can appear with no
      // items behind it, a photograph of a hand can become an entry again.
      expect(find.text('Save to log'), findsNothing);
    });

    testWidgets('offers a retry and the manual path', (tester) async {
      setItems(const []);
      await pump(tester);

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Add by hand instead'), findsOneWidget);
    });

    testWidgets('is not dressed as an error', (tester) async {
      setItems(const []);
      await pump(tester);

      // The model did its job. Blaming it — or the user — for a correct answer
      // is the wrong tone, and there is no red anywhere in this app.
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => (t.data ?? '').toLowerCase())
          .join(' ');
      expect(text, isNot(contains('error')));
      expect(text, isNot(contains('failed')));
      expect(text, isNot(contains('sorry')));
    });
  });

  group('when the photo has food in it', () {
    final items = [
      const ProposedItem(
        name: 'chicken biryani',
        grams: 300,
        macros: Macros(kcal: 620, proteinG: 28, carbsG: 72, fatG: 24),
        confidence: Confidence.high,
        confidenceReason: 'clear plate',
        portionDesc: '1 plate',
      ),
    ];

    testWidgets('lists it and offers to save', (tester) async {
      setItems(items);
      await pump(tester);

      expect(find.text('chicken biryani'), findsOneWidget);
      expect(find.text('Save to log'), findsOneWidget);
      expect(find.text('No food in that photo'), findsNothing);
    });

    testWidgets('shows the total across items', (tester) async {
      setItems(items);
      await pump(tester);
      // Twice over: once as the header total, once on the item's own card.
      expect(find.text('620 kcal'), findsNWidgets(2));
    });
  });

  group('while it is still thinking', () {
    testWidgets('shows skeletons, not a save button', (tester) async {
      container.read(photoAnalysisProvider.notifier).state =
          const AsyncLoading();
      await pump(tester);

      // SectionLabel uppercases, so this is what actually renders.
      expect(find.text('READING YOUR PHOTO'), findsOneWidget);
      expect(find.text('Save to log'), findsNothing);
    });
  });
}

/// The smallest valid JPEG, so `Image.file` has something real to decode.
const _onePixelJpeg = <int>[
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
  0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
  0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11,
  0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xFF, 0xC4,
  0x00, 0x14, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01,
  0x01, 0x00, 0x00, 0x3F, 0x00, 0x37, 0xFF, 0xD9,
];
