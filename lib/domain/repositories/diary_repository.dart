/// Read and write access to the user's diary.
///
/// The `watch*` methods return streams rather than futures on purpose. Drift
/// re-emits them whenever the underlying tables change, so the ring, the
/// totals, the protein pips and the calendar all update from a single write
/// with no manual invalidation. Hand-rolled refreshes after every insert, edit
/// and delete are exactly where "I deleted an item but the total didn't change"
/// bugs come from.
library;

import '../models/entry.dart';
import '../models/enums.dart';
import '../models/food.dart';

/// A food to be written onto an entry, before it has an id.
class NewItem {
  const NewItem({
    required this.name,
    required this.grams,
    required this.macros,
    required this.source,
    this.portionDesc,
    this.confidence,
    this.confidenceReason,
    this.foodId,
  });

  final String name;
  final double grams;
  final Macros macros;
  final ItemSource source;
  final String? portionDesc;
  final Confidence? confidence;
  final String? confidenceReason;
  final int? foodId;
}

/// The user's profile and the targets in force.
class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activity,
    required this.dailyKcal,
    required this.dailyProteinG,
    required this.dailyCarbsG,
    required this.dailyFatG,
    this.targetDate,
  });

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final ActivityLevel activity;

  final int dailyKcal;
  final int dailyProteinG;
  final int dailyCarbsG;
  final int dailyFatG;

  final DateTime? targetDate;
}

abstract interface class DiaryRepository {
  // ---- Profile ----------------------------------------------------------

  /// Null until onboarding completes. The app routes on this.
  Stream<UserProfile?> watchProfile();

  Future<UserProfile?> profile();

  Future<void> saveProfile(UserProfile profile);

  // ---- Entries ----------------------------------------------------------

  /// Entries for one civil day, ordered by time logged.
  Stream<List<LoggedEntry>> watchEntriesForDay(int dayKey);

  /// Totals for one day, against that day's target.
  Stream<DayTotals> watchTotalsForDay(int dayKey);

  /// Totals for every logged day in a month, keyed by day.
  ///
  /// One query per month, not one per cell — the calendar draws 35 cells and
  /// must not issue 35 reads.
  Stream<Map<int, DayTotals>> watchMonth(int year, int month);

  Future<int> addEntry({
    required int dayKey,
    required MealType mealType,
    required ItemSource source,
    required List<NewItem> items,
    String? photoPath,
    String? note,
  });

  Future<void> updateItem(int itemId, {double? grams, Macros? macros, String? portionDesc});

  Future<void> deleteItem(int itemId);

  /// Moves an entry to a different meal.
  ///
  /// The commonest correction after a portion: food logged at 4pm lands in
  /// "snack" by default, and sometimes it was lunch.
  Future<void> updateEntryMeal(int entryId, MealType meal);

  /// Removes an entry and its items.
  ///
  /// Does **not** purge `food_cache`: the learned nutrition value stays useful
  /// even when the meal it came from is gone.
  Future<void> deleteEntry(int entryId);

  // ---- Learned values ---------------------------------------------------

  /// A previously accepted value for [nameNormalised], if any.
  ///
  /// Checked before calling the vision API. A hit skips the network entirely
  /// and keeps a repeat meal reporting identical numbers, which matters more
  /// than being marginally more accurate: values that drift between identical
  /// meals read as a bug and cost trust faster than a small error does.
  Future<CachedFood?> cached(String nameNormalised);

  /// Records an **accepted** value, so the cache converges on the user's own
  /// corrections rather than on the model's first guess.
  Future<void> rememberFood(String nameNormalised, Macros per100g);

  /// Recent and frequent foods, shown before the user types anything.
  Future<List<CachedFood>> suggestions({int limit = 8});
}
