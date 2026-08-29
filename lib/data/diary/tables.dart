/// Drift table definitions for `diary.sqlite` — the writable, on-device
/// database holding the user's profile and everything they have logged.
///
/// Schema follows §8 of `01-concept.md`, with two deliberate departures noted
/// at [Entries.dayKey] and [EntryItems.foodId].
library;

import 'package:drift/drift.dart';

import '../../domain/models/enums.dart';

/// The user's profile and their computed daily targets.
///
/// Single-row in practice. The targets are stored rather than recomputed on
/// read so that changing a goal does not retroactively re-evaluate past days —
/// UC-10 requires history to stay judged against the target that was live at
/// the time.
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sex => textEnum<Sex>()();
  IntColumn get age => integer()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  RealColumn get targetWeightKg => real()();
  TextColumn get activityLevel => textEnum<ActivityLevel>()();

  /// The honest achievable date, after the goal engine's clamps. Null for a
  /// maintenance goal, which has no end date.
  DateTimeColumn get targetDate => dateTime().nullable()();

  IntColumn get dailyKcal => integer()();
  IntColumn get dailyProteinG => integer()();
  IntColumn get dailyCarbsG => integer()();
  IntColumn get dailyFatG => integer()();

  DateTimeColumn get updatedAt => dateTime()();
}

/// One logged eating occasion: a photo, or a manual add, or a set of items.
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The civil day as `yyyymmdd` (e.g. 20260826).
  ///
  /// Deliberately not a `DateTime`. Days are a calendar concept, not an
  /// instant: storing a timestamp makes "which day is this entry on" depend on
  /// the device time zone and on DST, so an entry logged at 00:30 can silently
  /// move to the previous day after travel. An integer civil date sorts
  /// correctly, indexes cheaply, and makes the calendar's month query a plain
  /// `BETWEEN`.
  IntColumn get dayKey => integer()();

  /// The actual instant of logging, for ordering within a day.
  DateTimeColumn get loggedAt => dateTime()();

  TextColumn get mealType => textEnum<MealType>()();

  /// Path to the retained photo, if this entry came from the camera. Retained
  /// even on failure so a retry costs nothing (UC-11).
  TextColumn get photoPath => text().nullable()();

  TextColumn get source => textEnum<ItemSource>()();
  TextColumn get note => text().nullable()();

  @override
  List<String> get customConstraints => const [];
}

/// A single food within an entry, with its macros already resolved.
///
/// Macros are denormalised at write time rather than recomputed from a food id.
/// This is what lets the diary stand alone: a rebuilt or replaced
/// `foods.sqlite` can never retroactively change what a past day says the user
/// ate.
class EntryItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();

  /// Normalised name, used as the `food_cache` key so a repeat meal resolves to
  /// the value the user already accepted.
  TextColumn get nameNormalised => text()();

  /// Human-readable portion, e.g. "1 plate", "2 tbsp".
  TextColumn get portionDesc => text().nullable()();

  RealColumn get grams => real()();

  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();

  /// Only set for AI-proposed items.
  TextColumn get confidence => textEnum<Confidence>().nullable()();
  TextColumn get confidenceReason => text().nullable()();

  TextColumn get source => textEnum<ItemSource>()();

  /// The `foods.id` this came from, when it came from the bundled database.
  ///
  /// **Not a foreign key.** `foods` lives in a separate database file that is
  /// never attached, so this cannot be enforced and must never be joined on.
  /// It exists for provenance — answering "where did this number come from" on
  /// the Sources screen — and nothing else.
  IntColumn get foodId => integer().nullable()();
}

/// Per-user learned nutrition values, keyed by normalised food name.
///
/// Populated from values the user **accepted**, not from what the model first
/// proposed, so it converges on their corrections. Its purpose is consistency:
/// the same food must report the same numbers every time, because varying
/// figures for a repeat meal read as a bug and destroy trust faster than being
/// slightly wrong (UC-12).
///
/// Deleting an entry does not purge this — the learned value stays useful.
class FoodCacheEntries extends Table {
  TextColumn get nameNormalised => text()();

  RealColumn get kcal100g => real()();
  RealColumn get protein100g => real()();
  RealColumn get carbs100g => real()();
  RealColumn get fat100g => real()();

  /// Drives the "recent" suggestions shown before the user types (UC-05).
  DateTimeColumn get lastUsedAt => dateTime()();

  /// How many times this value has been accepted. Drives "frequent".
  IntColumn get useCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {nameNormalised};
}
