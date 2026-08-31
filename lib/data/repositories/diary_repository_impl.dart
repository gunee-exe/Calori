/// Drift-backed [DiaryRepository].
///
/// The `watch*` methods lean on Drift re-emitting whenever the tables they read
/// change. One write updates the ring, the totals, the protein pips and the
/// calendar with no manual invalidation.
library;

import 'package:drift/drift.dart';

import '../../core/food_name.dart';

import '../../domain/models/day_key.dart';
import '../../domain/models/entry.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/repositories/diary_repository.dart';
import '../diary/diary_db.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  DiaryRepositoryImpl(this._db);

  final DiaryDb _db;

  // -- Profile ------------------------------------------------------------

  @override
  Stream<UserProfile?> watchProfile() =>
      _db.select(_db.profiles).watchSingleOrNull().map(_toProfile);

  @override
  Future<UserProfile?> profile() async =>
      _toProfile(await _db.select(_db.profiles).getSingleOrNull());

  @override
  Future<void> saveProfile(UserProfile p) async {
    final companion = ProfilesCompanion.insert(
      sex: p.sex,
      age: p.age,
      heightCm: p.heightCm,
      weightKg: p.weightKg,
      targetWeightKg: p.targetWeightKg,
      activityLevel: p.activity,
      dailyKcal: p.dailyKcal,
      dailyProteinG: p.dailyProteinG,
      dailyCarbsG: p.dailyCarbsG,
      dailyFatG: p.dailyFatG,
      updatedAt: DateTime.now(),
      targetDate: Value(p.targetDate),
    );

    // Single-row table: replace rather than accumulate revisions.
    await _db.transaction(() async {
      await _db.delete(_db.profiles).go();
      await _db.into(_db.profiles).insert(companion);
    });
  }

  // -- Entries ------------------------------------------------------------

  @override
  Stream<List<LoggedEntry>> watchEntriesForDay(int dayKey) {
    // The trigger declares **both** tables.
    //
    // Watching `entries` alone looks right and is not: the items are fetched
    // in a second query, so Drift is never told this stream depends on
    // `entry_items`. Editing a portion or removing one item then writes to the
    // database and re-emits nothing — the ring, the totals and the meal card
    // all keep showing the old figures until something else happens to touch
    // `entries`. Changing an entry's meal type appeared to work, which is what
    // made it look like a UI bug rather than a stale query.
    final trigger = _db
        .customSelect(
          'SELECT id FROM entries WHERE day_key = ? ORDER BY logged_at',
          variables: [Variable<int>(dayKey)],
          readsFrom: {_db.entries, _db.entryItems},
        )
        .watch();

    // Every entry's items in one query, joined in memory. The alternative —
    // a query per entry — turns a ten-meal day into eleven round trips.
    return trigger.asyncMap((_) async {
      final rows =
          await (_db.select(_db.entries)
                ..where((e) => e.dayKey.equals(dayKey))
                ..orderBy([(e) => OrderingTerm.asc(e.loggedAt)]))
              .get();

      if (rows.isEmpty) return const <LoggedEntry>[];

      final ids = rows.map((e) => e.id).toList();
      final items =
          await (_db.select(_db.entryItems)
                ..where((i) => i.entryId.isIn(ids))
                ..orderBy([(i) => OrderingTerm.asc(i.id)]))
              .get();

      final byEntry = <int, List<LoggedItem>>{};
      for (final item in items) {
        byEntry.putIfAbsent(item.entryId, () => []).add(_toItem(item));
      }

      return [
        for (final row in rows)
          LoggedEntry(
            id: row.id,
            dayKey: row.dayKey,
            loggedAt: row.loggedAt,
            mealType: row.mealType,
            source: row.source,
            photoPath: row.photoPath,
            note: row.note,
            items: byEntry[row.id] ?? const [],
          ),
      ];
    });
  }

  @override
  Stream<DayTotals> watchTotalsForDay(int dayKey) {
    return watchEntriesForDay(dayKey).asyncMap((entries) async {
      final target = (await profile())?.dailyKcal ?? 0;
      final consumed = entries.fold(
        Macros.zero,
        (sum, entry) => sum + entry.totals,
      );
      return DayTotals(
        dayKey: dayKey,
        consumed: consumed,
        targetKcal: target,
      );
    });
  }

  @override
  Stream<Map<int, DayTotals>> watchMonth(int year, int month) {
    final (start, end) = DayKey.monthBounds(year, month);

    // Aggregated in SQL. The calendar draws 35 cells and must not issue 35
    // queries, nor pull every item of every day into memory to add them up.
    final query = _db.customSelect(
      'SELECT e.day_key AS day_key, '
      '       SUM(i.kcal) AS kcal, '
      '       SUM(i.protein_g) AS protein_g, '
      '       SUM(i.carbs_g) AS carbs_g, '
      '       SUM(i.fat_g) AS fat_g '
      'FROM entries e '
      'JOIN entry_items i ON i.entry_id = e.id '
      'WHERE e.day_key BETWEEN ? AND ? '
      'GROUP BY e.day_key',
      variables: [Variable<int>(start), Variable<int>(end)],
      readsFrom: {_db.entries, _db.entryItems},
    ).watch();

    return query.asyncMap((rows) async {
      final target = (await profile())?.dailyKcal ?? 0;
      return {
        for (final row in rows)
          row.read<int>('day_key'): DayTotals(
            dayKey: row.read<int>('day_key'),
            consumed: Macros(
              kcal: row.read<double?>('kcal') ?? 0,
              proteinG: row.read<double?>('protein_g') ?? 0,
              carbsG: row.read<double?>('carbs_g') ?? 0,
              fatG: row.read<double?>('fat_g') ?? 0,
            ),
            targetKcal: target,
          ),
      };
    });
  }

  @override
  Future<int> addEntry({
    required int dayKey,
    required MealType mealType,
    required ItemSource source,
    required List<NewItem> items,
    String? photoPath,
    String? note,
  }) {
    // One transaction: an entry with no items would render as an empty meal
    // card and count for nothing.
    return _db.transaction(() async {
      final entryId = await _db
          .into(_db.entries)
          .insert(
            EntriesCompanion.insert(
              dayKey: dayKey,
              loggedAt: DateTime.now(),
              mealType: mealType,
              source: source,
              photoPath: Value(photoPath),
              note: Value(note),
            ),
          );

      for (final item in items) {
        await _db
            .into(_db.entryItems)
            .insert(_itemCompanion(entryId, item));
      }

      return entryId;
    });
  }

  @override
  Future<void> updateItem(
    int itemId, {
    double? grams,
    Macros? macros,
    String? portionDesc,
  }) async {
    await (_db.update(_db.entryItems)..where((i) => i.id.equals(itemId))).write(
      EntryItemsCompanion(
        grams: grams == null ? const Value.absent() : Value(grams),
        kcal: macros == null ? const Value.absent() : Value(macros.kcal),
        proteinG: macros == null ? const Value.absent() : Value(macros.proteinG),
        carbsG: macros == null ? const Value.absent() : Value(macros.carbsG),
        fatG: macros == null ? const Value.absent() : Value(macros.fatG),
        portionDesc:
            portionDesc == null ? const Value.absent() : Value(portionDesc),
      ),
    );
  }

  @override
  Future<void> updateEntryMeal(int entryId, MealType meal) async {
    await (_db.update(_db.entries)..where((e) => e.id.equals(entryId))).write(
      EntriesCompanion(mealType: Value(meal)),
    );
  }

  @override
  Future<void> deleteItem(int itemId) async {
    await _db.transaction(() async {
      final item = await (_db.select(_db.entryItems)
            ..where((i) => i.id.equals(itemId)))
          .getSingleOrNull();
      if (item == null) return;

      await (_db.delete(_db.entryItems)..where((i) => i.id.equals(itemId)))
          .go();

      // An entry whose last item was removed is not a meal any more. Leaving
      // it behind shows an empty card that cannot be dismissed.
      final remaining = await (_db.select(_db.entryItems)
            ..where((i) => i.entryId.equals(item.entryId)))
          .get();
      if (remaining.isEmpty) {
        await (_db.delete(_db.entries)..where((e) => e.id.equals(item.entryId)))
            .go();
      }
    });
  }

  @override
  Future<void> deleteEntry(int entryId) async {
    // entry_items cascades. food_cache deliberately does not: the learned
    // value stays useful after the meal it came from is gone.
    await (_db.delete(_db.entries)..where((e) => e.id.equals(entryId))).go();
  }

  // -- Learned values -----------------------------------------------------

  @override
  Future<CachedFood?> cached(String nameNormalised) async {
    final row = await (_db.select(_db.foodCacheEntries)
          ..where((c) => c.nameNormalised.equals(nameNormalised)))
        .getSingleOrNull();

    if (row == null) return null;
    return _toCached(row);
  }

  @override
  Future<void> rememberFood(String nameNormalised, Macros per100g) async {
    final existing = await cached(nameNormalised);

    await _db.into(_db.foodCacheEntries).insertOnConflictUpdate(
      FoodCacheEntriesCompanion.insert(
        nameNormalised: nameNormalised,
        kcal100g: per100g.kcal,
        protein100g: per100g.proteinG,
        carbs100g: per100g.carbsG,
        fat100g: per100g.fatG,
        lastUsedAt: DateTime.now(),
        useCount: Value((existing?.useCount ?? 0) + 1),
      ),
    );
  }

  @override
  Future<List<CachedFood>> suggestions({int limit = 8}) async {
    // Frequency first, recency second: the food you log every morning should
    // outrank the one you logged once yesterday.
    final rows =
        await (_db.select(_db.foodCacheEntries)
              ..orderBy([
                (c) => OrderingTerm.desc(c.useCount),
                (c) => OrderingTerm.desc(c.lastUsedAt),
              ])
              ..limit(limit))
            .get();

    return [for (final row in rows) _toCached(row)];
  }

  // -- Mapping ------------------------------------------------------------

  EntryItemsCompanion _itemCompanion(int entryId, NewItem item) =>
      EntryItemsCompanion.insert(
        entryId: entryId,
        name: item.name,
        // Must be the pinned normaliser, not toLowerCase(): this is the
        // food_cache key, and it has to agree with what the Python builder
        // wrote and what the AI path will look up.
        nameNormalised: normaliseFoodName(item.name),
        grams: item.grams,
        kcal: item.macros.kcal,
        proteinG: item.macros.proteinG,
        carbsG: item.macros.carbsG,
        fatG: item.macros.fatG,
        source: item.source,
        portionDesc: Value(item.portionDesc),
        confidence: Value(item.confidence),
        confidenceReason: Value(item.confidenceReason),
        foodId: Value(item.foodId),
      );

  LoggedItem _toItem(EntryItem row) => LoggedItem(
    id: row.id,
    name: row.name,
    grams: row.grams,
    macros: Macros(
      kcal: row.kcal,
      proteinG: row.proteinG,
      carbsG: row.carbsG,
      fatG: row.fatG,
    ),
    source: row.source,
    portionDesc: row.portionDesc,
    confidence: row.confidence,
    confidenceReason: row.confidenceReason,
    foodId: row.foodId,
  );

  CachedFood _toCached(FoodCacheEntry row) => CachedFood(
    nameNormalised: row.nameNormalised,
    per100g: Macros(
      kcal: row.kcal100g,
      proteinG: row.protein100g,
      carbsG: row.carbs100g,
      fatG: row.fat100g,
    ),
    lastUsedAt: row.lastUsedAt,
    useCount: row.useCount,
  );

  UserProfile? _toProfile(Profile? row) {
    if (row == null) return null;
    return UserProfile(
      sex: row.sex,
      age: row.age,
      heightCm: row.heightCm,
      weightKg: row.weightKg,
      targetWeightKg: row.targetWeightKg,
      activity: row.activityLevel,
      dailyKcal: row.dailyKcal,
      dailyProteinG: row.dailyProteinG,
      dailyCarbsG: row.dailyCarbsG,
      dailyFatG: row.dailyFatG,
      targetDate: row.targetDate,
    );
  }
}
