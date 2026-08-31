/// Imperial display over metric storage.
///
/// The risk these cover is a conversion that looks right in one direction and
/// silently loses a value in the other — someone types 5'10", and the profile
/// ends up holding a height that reads back as 5'9".
library;

import 'package:calori/core/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('height', () {
    test('converts the way a person would state it', () {
      expect(cmToFeetInches(177.8), (feet: 5, inches: 10));
      expect(cmToFeetInches(152.4), (feet: 5, inches: 0));
      expect(feetInchesToCm(5, 10), closeTo(177.8, 0.01));
      expect(feetInchesToCm(6, 0), closeTo(182.88, 0.01));
    });

    test('twelve inches roll over into a foot, never read as 5 foot 12', () {
      expect(cmToFeetInches(182.0), (feet: 6, inches: 0));

      for (var cm = 100.0; cm <= 250; cm += 0.1) {
        final (:feet, :inches) = cmToFeetInches(cm);
        expect(inches, inInclusiveRange(0, 11), reason: 'at $cm cm');
        expect(feet, greaterThan(0));
      }
    });

    test('a round trip stays within the rounding it promises', () {
      // Whole inches are the stated precision, so at most half an inch of
      // drift -- 1.27 cm -- is allowed, and it must not accumulate.
      for (var cm = 100.0; cm <= 250; cm += 0.5) {
        final (:feet, :inches) = cmToFeetInches(cm);
        final back = feetInchesToCm(feet, inches);
        expect((back - cm).abs(), lessThanOrEqualTo(cmPerInch / 2 + 0.001),
            reason: '$cm cm became $feet ft $inches in, which is $back cm');

        // A second trip must land exactly where the first did.
        final again = cmToFeetInches(back);
        expect(again, (feet: feet, inches: inches));
      }
    });

    test('formats as feet and inches, or as centimetres', () {
      expect(formatHeight(177.8, imperial: true), "5'10\"");
      expect(formatHeight(178, imperial: false), '178 cm');
    });
  });

  group('weight', () {
    test('a kilogram is 2.2 pounds, both ways', () {
      expect(kgToPounds(78), closeTo(171.96, 0.01));
      expect(poundsToKg(172), closeTo(78.02, 0.01));
    });

    test('a round trip through pounds is lossless', () {
      for (var kg = 25.0; kg <= 400; kg += 0.5) {
        expect(poundsToKg(kgToPounds(kg)), closeTo(kg, 0.0001));
      }
    });

    test('formats as pounds or kilograms', () {
      expect(formatWeight(78, imperial: true), '172 lb');
      expect(formatWeight(78, imperial: false), '78 kg');
    });
  });

  group('the bounds hold in both systems', () {
    test('the onboarding height range covers the heights people are', () {
      // 100-250 cm is checked against the converted value, so these are the
      // imperial ends of the same range.
      expect(feetInchesToCm(3, 4), greaterThanOrEqualTo(100));
      expect(feetInchesToCm(8, 2), lessThanOrEqualTo(250));
    });

    test('the onboarding weight range covers the weights people are', () {
      expect(poundsToKg(56), greaterThanOrEqualTo(25));
      expect(poundsToKg(880), lessThanOrEqualTo(400));
    });
  });
}
