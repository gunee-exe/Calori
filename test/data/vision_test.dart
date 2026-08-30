/// Parsing and failure handling for the photo path (UC-03, UC-04).
///
/// Runs against captured payloads rather than a live Worker. What matters here
/// is that a malformed or hostile response degrades into something the user can
/// act on, and never into a confident wrong number.
library;

import 'dart:convert';

import 'package:calori/data/ai/vision_service.dart';
import 'package:calori/domain/models/enums.dart';
import 'package:calori/domain/models/food.dart';
import 'package:flutter_test/flutter_test.dart';

String payload(List<Map<String, Object?>> items) =>
    jsonEncode({'items': items});

Map<String, Object?> item({
  String name = 'chicken biryani',
  Object? grams = 300,
  Object? kcal = 620,
  Object? protein = 28,
  Object? carbs = 72,
  Object? fat = 24,
  String confidence = 'high',
  String reason = 'clear plate, good reference',
  Object? portion = '1 plate',
}) => {
  'name': name,
  'grams': grams,
  'kcal': kcal,
  'protein_g': protein,
  'carbs_g': carbs,
  'fat_g': fat,
  'confidence': confidence,
  'confidence_reason': reason,
  'portion_desc': portion,
};

void main() {
  group('parsing a well-formed response', () {
    test('reads every field', () {
      final items = parseItems(payload([item()]));

      expect(items, hasLength(1));
      final first = items.single;
      expect(first.name, 'chicken biryani');
      expect(first.grams, 300);
      expect(first.macros.kcal, 620);
      expect(first.macros.proteinG, 28);
      expect(first.confidence, Confidence.high);
      expect(first.confidenceReason, 'clear plate, good reference');
      expect(first.portionDesc, '1 plate');
      expect(first.fromCache, isFalse);
    });

    test('handles several items', () {
      final items = parseItems(
        payload([item(name: 'roti', grams: 45), item(name: 'raita')]),
      );
      expect(items.map((i) => i.name), ['roti', 'raita']);
    });

    test('accepts numbers sent as strings', () {
      // Some providers stringify numbers despite the schema.
      final items = parseItems(payload([item(grams: '300', kcal: '620')]));
      expect(items.single.grams, 300);
      expect(items.single.macros.kcal, 620);
    });
  });

  group('a malformed response fails visibly', () {
    void expectsBadResponse(String body, String reason) {
      expect(
        () => parseItems(body),
        throwsA(
          isA<VisionException>().having(
            (e) => e.failure,
            'failure',
            VisionFailure.badResponse,
          ),
        ),
        reason: reason,
      );
    }

    test('not JSON at all', () {
      expectsBadResponse('I could not read that photo, sorry!', 'prose');
    });

    test('JSON without an items array', () {
      expectsBadResponse('{"result": "ok"}', 'wrong shape');
    });

    test('an empty items array', () {
      // Better a clear failure with a retry than an empty log entry the user
      // has to notice is empty.
      expectsBadResponse(payload([]), 'no items');
    });

    test('every item unusable', () {
      expectsBadResponse(
        payload([
          {'name': '', 'grams': 100, 'kcal': 200},
          {'name': 'x', 'grams': 0, 'kcal': 200},
        ]),
        'nothing salvageable',
      );
    });
  });

  group('individual bad items are dropped, not guessed at', () {
    test('an item with no name is skipped but its neighbours survive', () {
      final items = parseItems(payload([item(name: ''), item(name: 'rice')]));
      expect(items.map((i) => i.name), ['rice']);
    });

    test('an item with no calories is skipped', () {
      // A 0 kcal default would enter the log as a real food contributing
      // nothing, which is worse than it being absent.
      final items = parseItems(payload([item(kcal: null), item(name: 'dal')]));
      expect(items.map((i) => i.name), ['dal']);
    });

    test('an item with zero grams is skipped', () {
      final items = parseItems(payload([item(grams: 0), item(name: 'dal')]));
      expect(items.map((i) => i.name), ['dal']);
    });

    test('missing macros default to zero rather than dropping the food', () {
      final items = parseItems(
        payload([item(protein: null, carbs: null, fat: null)]),
      );
      expect(items.single.macros.kcal, 620);
      expect(items.single.macros.proteinG, 0);
    });
  });

  group('confidence', () {
    test('maps the three known values', () {
      for (final (raw, expected) in [
        ('high', Confidence.high),
        ('medium', Confidence.medium),
        ('low', Confidence.low),
      ]) {
        final items = parseItems(payload([item(confidence: raw)]));
        expect(items.single.confidence, expected);
      }
    });

    test('an unknown value is treated as low, not high', () {
      // Unrecognised input must make the app more cautious, never less: an
      // item marked low is shown blurred and asks for confirmation.
      for (final raw in ['certain', 'HIGH', '', 'very high']) {
        final items = parseItems(payload([item(confidence: raw)]));
        expect(items.single.confidence, Confidence.low, reason: raw);
      }
    });

    test('a missing reason still yields something to show', () {
      final items = parseItems(payload([item(reason: '')]));
      expect(items.single.confidenceReason, isNotEmpty);
    });
  });

  group('rescaling a portion', () {
    test('scales macros proportionally', () {
      final original = parseItems(payload([item()])).single;
      final doubled = original.macrosFor(600);

      expect(doubled.kcal, 1240);
      expect(doubled.proteinG, 56);
    });

    test('halving works too', () {
      final original = parseItems(payload([item()])).single;
      expect(original.macrosFor(150).kcal, 310);
    });

    test('a zero-gram item does not divide by zero', () {
      const zero = ProposedItem(
        name: 'x',
        grams: 0,
        macros: Macros(kcal: 100, proteinG: 1, carbsG: 1, fatG: 1),
        confidence: Confidence.low,
        confidenceReason: 'test',
      );
      expect(zero.macrosFor(100).kcal, 0);
    });

    test('copyWith preserves cache provenance', () {
      const cached = ProposedItem(
        name: 'roti',
        grams: 45,
        macros: Macros(kcal: 120, proteinG: 3, carbsG: 24, fatG: 1),
        confidence: Confidence.high,
        confidenceReason: 'you have logged this before',
        fromCache: true,
      );
      expect(cached.copyWith(grams: 90).fromCache, isTrue);
    });
  });

  group('failure messages', () {
    test('every failure names what still works', () {
      for (final failure in VisionFailure.values) {
        final message = VisionException(failure).message;

        expect(message, isNotEmpty, reason: failure.name);
        // Manual logging always works. Every failure on the photo path has to
        // point at it, because the user has just photographed a meal they are
        // about to stop caring about.
        expect(
          message.toLowerCase(),
          contains('hand'),
          reason: '${failure.name} does not offer manual logging',
        );
        // No blame, no jargon, no "unexpected error".
        expect(message.toLowerCase(), isNot(contains('error')));
        expect(message.toLowerCase(), isNot(contains('failed')));
      }
    });

    test('the rate-limit message does not sound like a fault', () {
      final message = const VisionException(
        VisionFailure.rateLimited,
      ).message.toLowerCase();
      expect(message, contains('unlimited'));
    });
  });
}
