/// Providers for the day view.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../domain/models/day_key.dart';
import '../../domain/models/entry.dart';
import '../../domain/repositories/diary_repository.dart';

part 'providers.g.dart';

/// The day currently being viewed, as `yyyymmdd`.
///
/// Held here rather than passed down so the date strip, the ring, the totals
/// and the meal list all read one source.
@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  int build() => DayKey.today();

  void select(int dayKey) => state = dayKey;
  void today() => state = DayKey.today();
}

/// The user's profile, or null before onboarding.
///
/// The app routes on this: null means the goal has never been set.
@riverpod
Stream<UserProfile?> profile(Ref ref) =>
    ref.watch(diaryRepositoryProvider).watchProfile();

/// Entries for the selected day, grouped as logged.
@riverpod
Stream<List<LoggedEntry>> entriesForSelectedDay(Ref ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchEntriesForDay(ref.watch(selectedDayProvider));
}

/// Totals for the selected day against that day's target.
///
/// A stream, not a future: Drift re-emits when anything writes to entries or
/// items, so saving a food updates the ring without anyone invalidating it.
@riverpod
Stream<DayTotals> totalsForSelectedDay(Ref ref) {
  return ref
      .watch(diaryRepositoryProvider)
      .watchTotalsForDay(ref.watch(selectedDayProvider));
}
