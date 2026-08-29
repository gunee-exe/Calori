/// Conversions between a [DateTime] and the integer civil date used as
/// `entries.day_key`.
///
/// A day is a calendar concept, not an instant. Storing entries against a
/// timestamp makes "which day is this on" depend on the device time zone, so an
/// entry logged at 00:30 can silently move to the previous day after the user
/// travels or the clocks change. An integer `yyyymmdd` has no such ambiguity,
/// sorts correctly, indexes cheaply, and turns the calendar's month query into
/// a plain `BETWEEN`.
library;

extension DayKeyFromDate on DateTime {
  /// This date as `yyyymmdd`, e.g. 20260826.
  ///
  /// Uses the local calendar fields, which is the point: the day a meal belongs
  /// to is the day it was for the person eating it.
  int get dayKey => year * 10000 + month * 100 + day;
}

abstract final class DayKey {
  /// The civil date for [at], defaulting to now.
  static int of(DateTime at) => at.dayKey;

  static int today([DateTime? now]) => (now ?? DateTime.now()).dayKey;

  /// Expands a key back into a `DateTime` at local midnight.
  static DateTime toDate(int key) {
    return DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);
  }

  /// Inclusive key bounds covering the whole of [month].
  ///
  /// Feeds the calendar's single month query. Using the last *day* of the month
  /// rather than the first of the next avoids an off-by-one at year boundaries.
  static (int start, int end) monthBounds(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return (year * 10000 + month * 100 + 1, year * 10000 + month * 100 + lastDay);
  }

  /// Shifts a key by [days], going through `DateTime` so month and year
  /// rollovers and leap days are handled by the calendar, not by arithmetic.
  static int addDays(int key, int days) =>
      toDate(key).add(Duration(days: days)).dayKey;

  /// Whole days from [from] to [to]. Negative when [to] is earlier.
  static int difference(int from, int to) =>
      toDate(to).difference(toDate(from)).inDays;
}
