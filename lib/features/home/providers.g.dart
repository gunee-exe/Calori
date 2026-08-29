// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The day currently being viewed, as `yyyymmdd`.
///
/// Held here rather than passed down so the date strip, the ring, the totals
/// and the meal list all read one source.

@ProviderFor(SelectedDay)
final selectedDayProvider = SelectedDayProvider._();

/// The day currently being viewed, as `yyyymmdd`.
///
/// Held here rather than passed down so the date strip, the ring, the totals
/// and the meal list all read one source.
final class SelectedDayProvider extends $NotifierProvider<SelectedDay, int> {
  /// The day currently being viewed, as `yyyymmdd`.
  ///
  /// Held here rather than passed down so the date strip, the ring, the totals
  /// and the meal list all read one source.
  SelectedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDayHash();

  @$internal
  @override
  SelectedDay create() => SelectedDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$selectedDayHash() => r'7869220032d022e59b8d8cad40bb7a0072b2b49c';

/// The day currently being viewed, as `yyyymmdd`.
///
/// Held here rather than passed down so the date strip, the ring, the totals
/// and the meal list all read one source.

abstract class _$SelectedDay extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The user's profile, or null before onboarding.
///
/// The app routes on this: null means the goal has never been set.

@ProviderFor(profile)
final profileProvider = ProfileProvider._();

/// The user's profile, or null before onboarding.
///
/// The app routes on this: null means the goal has never been set.

final class ProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  /// The user's profile, or null before onboarding.
  ///
  /// The app routes on this: null means the goal has never been set.
  ProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return profile(ref);
  }
}

String _$profileHash() => r'c13ba682fbd6ed5c646cb1a8c3cb1d1096943252';

/// Entries for the selected day, grouped as logged.

@ProviderFor(entriesForSelectedDay)
final entriesForSelectedDayProvider = EntriesForSelectedDayProvider._();

/// Entries for the selected day, grouped as logged.

final class EntriesForSelectedDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoggedEntry>>,
          List<LoggedEntry>,
          Stream<List<LoggedEntry>>
        >
    with
        $FutureModifier<List<LoggedEntry>>,
        $StreamProvider<List<LoggedEntry>> {
  /// Entries for the selected day, grouped as logged.
  EntriesForSelectedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entriesForSelectedDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entriesForSelectedDayHash();

  @$internal
  @override
  $StreamProviderElement<List<LoggedEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LoggedEntry>> create(Ref ref) {
    return entriesForSelectedDay(ref);
  }
}

String _$entriesForSelectedDayHash() =>
    r'93f03fcb7c82a8005de81f79ce82ae10443740ca';

/// Totals for the selected day against that day's target.
///
/// A stream, not a future: Drift re-emits when anything writes to entries or
/// items, so saving a food updates the ring without anyone invalidating it.

@ProviderFor(totalsForSelectedDay)
final totalsForSelectedDayProvider = TotalsForSelectedDayProvider._();

/// Totals for the selected day against that day's target.
///
/// A stream, not a future: Drift re-emits when anything writes to entries or
/// items, so saving a food updates the ring without anyone invalidating it.

final class TotalsForSelectedDayProvider
    extends
        $FunctionalProvider<AsyncValue<DayTotals>, DayTotals, Stream<DayTotals>>
    with $FutureModifier<DayTotals>, $StreamProvider<DayTotals> {
  /// Totals for the selected day against that day's target.
  ///
  /// A stream, not a future: Drift re-emits when anything writes to entries or
  /// items, so saving a food updates the ring without anyone invalidating it.
  TotalsForSelectedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalsForSelectedDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalsForSelectedDayHash();

  @$internal
  @override
  $StreamProviderElement<DayTotals> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DayTotals> create(Ref ref) {
    return totalsForSelectedDay(ref);
  }
}

String _$totalsForSelectedDayHash() =>
    r'd5217a0a24f27403d6f4fb11c6d38f9c4eae9d5e';
