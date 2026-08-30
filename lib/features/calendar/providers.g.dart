// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The month on screen, as (year, month).
///
/// Kept alive so paging back through several months and returning to Home does
/// not reset the view to today.

@ProviderFor(VisibleMonth)
final visibleMonthProvider = VisibleMonthProvider._();

/// The month on screen, as (year, month).
///
/// Kept alive so paging back through several months and returning to Home does
/// not reset the view to today.
final class VisibleMonthProvider
    extends $NotifierProvider<VisibleMonth, ({int month, int year})> {
  /// The month on screen, as (year, month).
  ///
  /// Kept alive so paging back through several months and returning to Home does
  /// not reset the view to today.
  VisibleMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleMonthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleMonthHash();

  @$internal
  @override
  VisibleMonth create() => VisibleMonth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int month, int year}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int month, int year})>(value),
    );
  }
}

String _$visibleMonthHash() => r'0424bfb250c70c47dc91e357368e3085fa299295';

/// The month on screen, as (year, month).
///
/// Kept alive so paging back through several months and returning to Home does
/// not reset the view to today.

abstract class _$VisibleMonth extends $Notifier<({int month, int year})> {
  ({int month, int year}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<({int month, int year}), ({int month, int year})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<({int month, int year}), ({int month, int year})>,
              ({int month, int year}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Totals for every logged day in the visible month, keyed by day.

@ProviderFor(monthTotals)
final monthTotalsProvider = MonthTotalsProvider._();

/// Totals for every logged day in the visible month, keyed by day.

final class MonthTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, DayTotals>>,
          Map<int, DayTotals>,
          Stream<Map<int, DayTotals>>
        >
    with
        $FutureModifier<Map<int, DayTotals>>,
        $StreamProvider<Map<int, DayTotals>> {
  /// Totals for every logged day in the visible month, keyed by day.
  MonthTotalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthTotalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthTotalsHash();

  @$internal
  @override
  $StreamProviderElement<Map<int, DayTotals>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, DayTotals>> create(Ref ref) {
    return monthTotals(ref);
  }
}

String _$monthTotalsHash() => r'26ccf5f5270b3d65942e56eb1b30f4589185ec44';

/// The day whose detail card is shown beneath the grid.
///
/// Null means "no day picked yet", which renders the month summary instead.

@ProviderFor(SelectedCalendarDay)
final selectedCalendarDayProvider = SelectedCalendarDayProvider._();

/// The day whose detail card is shown beneath the grid.
///
/// Null means "no day picked yet", which renders the month summary instead.
final class SelectedCalendarDayProvider
    extends $NotifierProvider<SelectedCalendarDay, int?> {
  /// The day whose detail card is shown beneath the grid.
  ///
  /// Null means "no day picked yet", which renders the month summary instead.
  SelectedCalendarDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCalendarDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCalendarDayHash();

  @$internal
  @override
  SelectedCalendarDay create() => SelectedCalendarDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$selectedCalendarDayHash() =>
    r'c6fa318a79c0656e6f0a579f3541f866b76870b9';

/// The day whose detail card is shown beneath the grid.
///
/// Null means "no day picked yet", which renders the month summary instead.

abstract class _$SelectedCalendarDay extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Entries for the day selected in the calendar.

@ProviderFor(selectedCalendarDayEntries)
final selectedCalendarDayEntriesProvider =
    SelectedCalendarDayEntriesProvider._();

/// Entries for the day selected in the calendar.

final class SelectedCalendarDayEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoggedEntry>>,
          List<LoggedEntry>,
          Stream<List<LoggedEntry>>
        >
    with
        $FutureModifier<List<LoggedEntry>>,
        $StreamProvider<List<LoggedEntry>> {
  /// Entries for the day selected in the calendar.
  SelectedCalendarDayEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCalendarDayEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCalendarDayEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<LoggedEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LoggedEntry>> create(Ref ref) {
    return selectedCalendarDayEntries(ref);
  }
}

String _$selectedCalendarDayEntriesHash() =>
    r'239f3299c0e9cda253b8215d74703050542493f5';

/// Aggregate figures for the visible month.
///
/// Averages are over **logged days only**. Dividing by the length of the month
/// would drag every average toward zero for anyone who missed a day, which
/// turns a summary into a scolding.

@ProviderFor(monthSummary)
final monthSummaryProvider = MonthSummaryProvider._();

/// Aggregate figures for the visible month.
///
/// Averages are over **logged days only**. Dividing by the length of the month
/// would drag every average toward zero for anyone who missed a day, which
/// turns a summary into a scolding.

final class MonthSummaryProvider
    extends
        $FunctionalProvider<
          ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays}),
          ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays}),
          ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays})
        >
    with
        $Provider<
          ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays})
        > {
  /// Aggregate figures for the visible month.
  ///
  /// Averages are over **logged days only**. Dividing by the length of the month
  /// would drag every average toward zero for anyone who missed a day, which
  /// turns a summary into a scolding.
  MonthSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthSummaryHash();

  @$internal
  @override
  $ProviderElement<
    ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays})
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays}) create(
    Ref ref,
  ) {
    return monthSummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays}) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({int avgKcal, int avgProtein, int loggedDays, int onTargetDays})
          >(value),
    );
  }
}

String _$monthSummaryHash() => r'1c3ba2c5cf2786af5e8cc15b0115551f242d1ef2';
