/// Read access to the bundled food database.
library;

import '../models/food.dart';

/// One contributing dataset, as recorded in the shipped database's `meta`
/// table. Drives the Sources screen, so it always describes what actually
/// shipped rather than what the docs claim.
class DataSourceInfo {
  const DataSourceInfo({
    required this.id,
    required this.name,
    required this.licence,
    required this.attribution,
    this.url,
    this.retrievedAt,
  });

  final String id;
  final String name;
  final String licence;

  /// The exact wording the licence requires, rendered verbatim.
  final String attribution;

  final String? url;
  final String? retrievedAt;
}

abstract interface class FoodRepository {
  /// Ranked full-text search.
  ///
  /// Implementations must escape [query] into a valid FTS5 expression and
  /// return an empty list for input with nothing searchable in it, rather than
  /// letting an empty MATCH reach SQLite, where it is a runtime error.
  Future<List<Food>> search(String query, {int limit = 30});

  Future<Food?> byId(int id);

  /// Portions for [foodId], default first.
  Future<List<FoodPortion>> portionsFor(int foodId);

  /// The provenance manifest baked into the shipped database.
  Future<List<DataSourceInfo>> sources();

  /// The database build version, for display and for support questions.
  Future<String?> buildVersion();
}
