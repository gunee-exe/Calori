// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The text currently in the search field.

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

/// The text currently in the search field.
final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  /// The text currently in the search field.
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'352ea7d62d8173005ae64d81558a6bf93f929545';

/// The text currently in the search field.

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Debounced search results.
///
/// The timer is held by this notifier and cancelled in `onDispose`. Riverpod 3
/// builds a **fresh notifier instance on every rebuild** — the 2.x
/// pseudo-singleton is gone — so a timer left running here leaks one per
/// keystroke.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Debounced search results.
///
/// The timer is held by this notifier and cancelled in `onDispose`. Riverpod 3
/// builds a **fresh notifier instance on every rebuild** — the 2.x
/// pseudo-singleton is gone — so a timer left running here leaks one per
/// keystroke.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Food>>,
          List<Food>,
          FutureOr<List<Food>>
        >
    with $FutureModifier<List<Food>>, $FutureProvider<List<Food>> {
  /// Debounced search results.
  ///
  /// The timer is held by this notifier and cancelled in `onDispose`. Riverpod 3
  /// builds a **fresh notifier instance on every rebuild** — the 2.x
  /// pseudo-singleton is gone — so a timer left running here leaks one per
  /// keystroke.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<Food>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Food>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'6c98734f2b6a0788b2dea2d8d4ead4b90cde03bc';

/// Recent and frequent foods, shown before anything is typed (UC-05 step 2).

@ProviderFor(foodSuggestions)
final foodSuggestionsProvider = FoodSuggestionsProvider._();

/// Recent and frequent foods, shown before anything is typed (UC-05 step 2).

final class FoodSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CachedFood>>,
          List<CachedFood>,
          FutureOr<List<CachedFood>>
        >
    with $FutureModifier<List<CachedFood>>, $FutureProvider<List<CachedFood>> {
  /// Recent and frequent foods, shown before anything is typed (UC-05 step 2).
  FoodSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodSuggestionsHash();

  @$internal
  @override
  $FutureProviderElement<List<CachedFood>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CachedFood>> create(Ref ref) {
    return foodSuggestions(ref);
  }
}

String _$foodSuggestionsHash() => r'b9d0a255bed0f618afd6822b8ce6e420621bdadb';
