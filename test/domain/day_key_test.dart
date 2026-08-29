import 'package:calori/domain/models/day_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayKey', () {
    test('encodes a date as yyyymmdd', () {
      expect(DateTime(2026, 8, 26).dayKey, 20260826);
      expect(DateTime(2026, 1, 1).dayKey, 20260101);
      expect(DateTime(2026, 12, 31).dayKey, 20261231);
    });

    test('round-trips through a DateTime at local midnight', () {
      final d = DateTime(2026, 8, 26);
      expect(DayKey.toDate(d.dayKey), d);
    });

    test('the time of day never changes which day an entry belongs to', () {
      // The whole reason for an integer civil date: a meal logged at 00:30 or
      // at 23:59 belongs to the day it was for the person eating it.
      expect(DateTime(2026, 8, 26, 0, 30).dayKey, 20260826);
      expect(DateTime(2026, 8, 26, 23, 59, 59).dayKey, 20260826);
    });

    test('keys sort chronologically as plain integers', () {
      final keys = [
        DateTime(2027, 1, 1).dayKey,
        DateTime(2026, 8, 26).dayKey,
        DateTime(2026, 12, 31).dayKey,
        DateTime(2026, 9, 1).dayKey,
      ]..sort();

      expect(keys, [20260826, 20260901, 20261231, 20270101]);
    });

    group('monthBounds', () {
      test('covers a 31-day month', () {
        expect(DayKey.monthBounds(2026, 8), (20260801, 20260831));
      });

      test('covers a 30-day month', () {
        expect(DayKey.monthBounds(2026, 9), (20260901, 20260930));
      });

      test('handles February in a common year and a leap year', () {
        expect(DayKey.monthBounds(2026, 2), (20260201, 20260228));
        expect(DayKey.monthBounds(2028, 2), (20280201, 20280229));
      });

      test('December ends on the 31st, not in the following year', () {
        expect(DayKey.monthBounds(2026, 12), (20261201, 20261231));
      });
    });

    group('addDays', () {
      test('rolls over a month boundary', () {
        expect(DayKey.addDays(20260831, 1), 20260901);
      });

      test('rolls over a year boundary', () {
        expect(DayKey.addDays(20261231, 1), 20270101);
      });

      test('handles a leap day', () {
        expect(DayKey.addDays(20280228, 1), 20280229);
        expect(DayKey.addDays(20280229, 1), 20280301);
      });

      test('goes backwards', () {
        expect(DayKey.addDays(20260901, -1), 20260831);
      });
    });

    test('difference counts whole days across boundaries', () {
      expect(DayKey.difference(20260826, 20260826), 0);
      expect(DayKey.difference(20260826, 20260901), 6);
      expect(DayKey.difference(20261231, 20270101), 1);
      expect(DayKey.difference(20260901, 20260826), -6);
    });
  });
}
