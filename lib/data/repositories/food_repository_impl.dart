/// Drift-backed [FoodRepository].
///
/// Maps generated rows onto domain models. Drift generates a row class also
/// called `Food`, so the generated database is imported with a prefix to keep
/// the two apart.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/food_name.dart';
import '../../domain/models/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../foods/foods_db.dart' as db;
import '../foods/fts_query.dart';

class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl(this._db);

  final db.FoodsDb _db;

  @override
  Future<List<Food>> search(String query, {int limit = 30}) async {
    final match = buildFtsQuery(query);

    // An empty MATCH expression is a runtime error in SQLite, not an empty
    // result set. Punctuation-only input reaches here as an empty string.
    if (match.isEmpty) return const [];

    final rows = await _db
        .searchFoods(
          query: match,
          // The prefix tier compares against `name_normalised`, which the
          // Python builder wrote. normaliseFoodName is pinned to that same
          // implementation by test/core/food_name_test.dart.
          prefix: normaliseFoodName(query),
          lim: limit,
        )
        .get();

    if (rows.isEmpty) return const [];

    // One query for every portion in the result set, rather than one per row.
    final portions = await _portionsFor(rows.map((r) => r.f.id).toList());

    return [
      for (final row in rows) _toFood(row.f, portions[row.f.id] ?? const []),
    ];
  }

  @override
  Future<Food?> byId(int id) async {
    final rows = await _db.foodById(id: id).get();
    if (rows.isEmpty) return null;
    return _toFood(rows.first, await portionsFor(id));
  }

  @override
  Future<List<FoodPortion>> portionsFor(int foodId) async {
    final rows = await _db.portionsForFood(foodId: foodId).get();
    return [
      for (final row in rows)
        FoodPortion(
          label: row.label,
          grams: row.grams,
          isDefault: row.isDefault == 1,
        ),
    ];
  }

  /// Batched portion lookup, so a 30-row result list costs one query.
  Future<Map<int, List<FoodPortion>>> _portionsFor(List<int> foodIds) async {
    if (foodIds.isEmpty) return const {};

    final rows = await _db.customSelect(
      'SELECT food_id, label, grams, is_default FROM food_portions '
      'WHERE food_id IN (${List.filled(foodIds.length, '?').join(',')}) '
      'ORDER BY food_id, is_default DESC, grams ASC',
      variables: [for (final id in foodIds) Variable<int>(id)],
      readsFrom: {_db.foodPortions},
    ).get();

    final out = <int, List<FoodPortion>>{};
    for (final row in rows) {
      out.putIfAbsent(row.read<int>('food_id'), () => []).add(
        FoodPortion(
          label: row.read<String>('label'),
          grams: row.read<double>('grams'),
          isDefault: row.read<int>('is_default') == 1,
        ),
      );
    }
    return out;
  }

  @override
  Future<List<DataSourceInfo>> sources() async {
    final meta = await _meta();

    final ids = (meta['source_ids'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty);

    final out = <DataSourceInfo>[];
    for (final id in ids) {
      final raw = meta['source.$id'];
      if (raw == null) continue;

      // Written by tools/build_foods_db/manifest.py as one JSON blob per
      // source, so a source the app has never heard of still renders.
      final json = jsonDecode(raw) as Map<String, dynamic>;
      out.add(
        DataSourceInfo(
          id: id,
          name: json['name'] as String? ?? id,
          licence: json['licence'] as String? ?? '',
          attribution: json['attribution'] as String? ?? '',
          url: json['url'] as String?,
        ),
      );
    }

    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  @override
  Future<String?> buildVersion() async => (await _meta())['build_version'];

  Future<Map<String, String>> _meta() async {
    final rows = await _db.allMeta().get();
    return {for (final row in rows) row.name: row.value};
  }

  Food _toFood(db.Food row, List<FoodPortion> portions) => Food(
    id: row.id,
    name: row.name,
    nameNormalised: row.nameNormalised,
    source: row.source,
    localeHint: row.localeHint,
    per100g: Macros(
      kcal: row.kcal100g,
      proteinG: row.protein100g,
      carbsG: row.carbs100g,
      fatG: row.fat100g,
    ),
    portions: portions,
  );
}
