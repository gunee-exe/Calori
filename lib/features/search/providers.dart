/// Providers for the manual food search.
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../domain/models/food.dart';

part 'providers.g.dart';

/// How long typing must pause before a query runs.
///
/// Long enough that a fast typist issues one query rather than eight, short
/// enough that the list does not feel stalled.
const _debounce = Duration(milliseconds: 250);

/// The text currently in the search field.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

/// Debounced search results.
///
/// The timer is held by this notifier and cancelled in `onDispose`. Riverpod 3
/// builds a **fresh notifier instance on every rebuild** — the 2.x
/// pseudo-singleton is gone — so a timer left running here leaks one per
/// keystroke.
@riverpod
Future<List<Food>> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) return const [];

  // Read the repository before the await. Watching across an async gap is a
  // subscription this provider may no longer be entitled to.
  final repository = ref.watch(foodRepositoryProvider);

  var disposed = false;
  ref.onDispose(() => disposed = true);

  await Future<void>.delayed(_debounce);

  if (disposed) {
    // A newer keystroke replaced this provider mid-debounce. Returning a
    // future that never completes leaves the superseded instance quiet;
    // throwing here would surface an error state on a provider nobody is
    // watching any more, and would flash in the UI on a slow frame.
    return Completer<List<Food>>().future;
  }

  return repository.search(query);
}

/// Recent and frequent foods, shown before anything is typed (UC-05 step 2).
@riverpod
Future<List<CachedFood>> foodSuggestions(Ref ref) {
  return ref.watch(diaryRepositoryProvider).suggestions();
}
