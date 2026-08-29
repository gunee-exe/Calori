/// Domain models for logged entries and day totals.
library;

import 'enums.dart';
import 'food.dart';

/// One food on a logged entry, with its macros already resolved.
///
/// Macros are stored rather than derived, so a rebuilt `foods.sqlite` can never
/// retroactively change what a past day says the user ate.
class LoggedItem {
  const LoggedItem({
    required this.id,
    required this.name,
    required this.grams,
    required this.macros,
    required this.source,
    this.portionDesc,
    this.confidence,
    this.confidenceReason,
    this.foodId,
  });

  final int id;
  final String name;
  final double grams;
  final Macros macros;
  final ItemSource source;

  /// Human-readable portion, e.g. "1 plate", "2 tbsp".
  final String? portionDesc;

  /// Only present on AI-proposed items.
  final Confidence? confidence;
  final String? confidenceReason;

  /// Provenance only. Points into a different database file and must never be
  /// joined on.
  final int? foodId;

  /// Whether this item should render soft-focused, awaiting confirmation.
  ///
  /// The signature interaction: a low-confidence AI estimate is shown blurred
  /// and dimmed rather than flagged in a warning colour, and snaps sharp once
  /// the user commits to a portion.
  bool get needsConfirmation =>
      source == ItemSource.ai && confidence == Confidence.low;
}

/// One eating occasion: a photo, a manual add, or a set of items.
class LoggedEntry {
  const LoggedEntry({
    required this.id,
    required this.dayKey,
    required this.loggedAt,
    required this.mealType,
    required this.source,
    required this.items,
    this.photoPath,
    this.note,
  });

  final int id;
  final int dayKey;
  final DateTime loggedAt;
  final MealType mealType;
  final ItemSource source;
  final List<LoggedItem> items;

  /// Retained even when analysis failed, so a retry costs the user nothing.
  final String? photoPath;

  final String? note;

  Macros get totals =>
      items.fold(Macros.zero, (sum, item) => sum + item.macros);

  /// The one-line summary on a meal card: "Chicken biryani, raita".
  String get summary => items.map((i) => i.name).join(', ');

  /// Whether any item still wants the user's eye.
  bool get hasUnconfirmed => items.any((i) => i.needsConfirmation);
}

/// A day's consumption measured against that day's target.
class DayTotals {
  const DayTotals({
    required this.dayKey,
    required this.consumed,
    required this.targetKcal,
  });

  const DayTotals.empty(this.dayKey, this.targetKcal) : consumed = Macros.zero;

  final int dayKey;
  final Macros consumed;

  /// The target that was live on this day. Stored per day rather than derived
  /// from the current profile, because changing a goal must not retroactively
  /// re-judge history (UC-10).
  final int targetKcal;

  bool get isLogged => consumed.kcal > 0;

  /// Consumed over target. May exceed 1, which is what draws the ring's dim
  /// second lap. Guards a zero target rather than returning infinity.
  double get progress => targetKcal <= 0 ? 0 : consumed.kcal / targetKcal;

  bool get isOver => consumed.kcal > targetKcal;

  /// Always positive. Pair with [isOver] to pick the wording — the UI reads
  /// "left today" or "over today" and never shows a negative number, because a
  /// minus sign in front of a calorie count reads as a penalty.
  double get remainingAbs => (targetKcal - consumed.kcal).abs();

  /// How a calendar cell should render this day.
  DayOutcome get outcome {
    if (!isLogged) return DayOutcome.notLogged;
    return isOver ? DayOutcome.over : DayOutcome.onTarget;
  }
}

/// How a day reads at a glance on the calendar.
///
/// [notLogged] is deliberately its own state rather than a zero: an unlogged
/// day is *absent*, not a failure, and renders as a small neutral dot.
enum DayOutcome { onTarget, over, notLogged }
