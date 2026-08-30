/// Providers for the month view (UC-08).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../domain/models/day_key.dart';
import '../../domain/models/entry.dart';

part 'providers.g.dart';

/// The month on screen, as (year, month).
///
/// Kept alive so paging back through several months and returning to Home does
/// not reset the view to today.
@Riverpod(keepAlive: true)
class VisibleMonth extends _$VisibleMonth {
  @override
  ({int year, int month}) build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  void next() {
    final capped = DateTime.now();
    if (state.year == capped.year && state.month == capped.month) return;
    _shift(1);
  }

  void previous() => _shift(-1);

  void _shift(int months) {
    final moved = DateTime(state.year, state.month + months);
    state = (year: moved.year, month: moved.month);
  }

  /// Whether the forward arrow should be offered.
  ///
  /// There is nothing to show beyond the current month, and letting someone
  /// page into empty future months makes the calendar feel broken.
  bool get canGoForward {
    final now = DateTime.now();
    return state.year != now.year || state.month != now.month;
  }
}

/// Totals for every logged day in the visible month, keyed by day.
@riverpod
Stream<Map<int, DayTotals>> monthTotals(Ref ref) {
  final month = ref.watch(visibleMonthProvider);
  return ref
      .watch(diaryRepositoryProvider)
      .watchMonth(month.year, month.month);
}

/// The day whose detail card is shown beneath the grid.
///
/// Null means "no day picked yet", which renders the month summary instead.
@riverpod
class SelectedCalendarDay extends _$SelectedCalendarDay {
  @override
  int? build() => null;

  void select(int? dayKey) => state = dayKey;
}

/// Entries for the day selected in the calendar.
@riverpod
Stream<List<LoggedEntry>> selectedCalendarDayEntries(Ref ref) {
  final dayKey = ref.watch(selectedCalendarDayProvider);
  if (dayKey == null) return Stream.value(const []);
  return ref.watch(diaryRepositoryProvider).watchEntriesForDay(dayKey);
}

/// Aggregate figures for the visible month.
///
/// Averages are over **logged days only**. Dividing by the length of the month
/// would drag every average toward zero for anyone who missed a day, which
/// turns a summary into a scolding.
@riverpod
({int loggedDays, int avgKcal, int avgProtein, int onTargetDays})
monthSummary(Ref ref) {
  final totals = ref.watch(monthTotalsProvider).value ?? const {};
  final logged = totals.values.where((t) => t.isLogged).toList();

  if (logged.isEmpty) {
    return (loggedDays: 0, avgKcal: 0, avgProtein: 0, onTargetDays: 0);
  }

  final kcal = logged.fold(0.0, (sum, t) => sum + t.consumed.kcal);
  final protein = logged.fold(0.0, (sum, t) => sum + t.consumed.proteinG);

  return (
    loggedDays: logged.length,
    avgKcal: (kcal / logged.length).round(),
    avgProtein: (protein / logged.length).round(),
    onTargetDays: logged.where((t) => !t.isOver).length,
  );
}

/// The cells of the month grid, Monday-first, padded to whole weeks.
///
/// Leading and trailing nulls are blanks rather than neighbouring months'
/// days: showing a greyed-out 31st of last month invites tapping it, and the
/// calendar only ever shows one month's data.
List<int?> monthGridCells(int year, int month) {
  final first = DateTime(year, month);
  final daysInMonth = DateTime(year, month + 1, 0).day;

  // DateTime.weekday is 1=Mon..7=Sun, which is already Monday-first.
  final leading = first.weekday - 1;

  final cells = <int?>[
    ...List<int?>.filled(leading, null),
    for (var day = 1; day <= daysInMonth; day++)
      DayKey.of(DateTime(year, month, day)),
  ];

  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}
