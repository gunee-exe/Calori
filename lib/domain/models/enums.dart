/// Enumerations shared by the domain layer and both databases.
///
/// These are persisted by *name* (Drift `textEnum`), not by index, so reordering
/// or inserting a value can never silently reinterpret existing rows.
library;

/// Biological sex, used by Mifflin-St Jeor and by the calorie floor.
///
/// This is a metabolic input, not an identity field. It appears exactly twice:
/// the `+5 / −161` constant in the BMR equation, and the 1500/1200 kcal floor.
enum Sex {
  male,
  female;

  /// The Mifflin-St Jeor constant.
  int get bmrConstant => switch (this) { Sex.male => 5, Sex.female => -161 };

  /// The hard calorie floor the goal engine clamps to.
  ///
  /// See `05-build-plan.md` — these figures are widely repeated in consumer
  /// health guidance and still need tracing to an authoritative source before
  /// they are defended.
  int get calorieFloor => switch (this) { Sex.male => 1500, Sex.female => 1200 };
}

/// Standard activity multipliers applied to BMR to reach TDEE.
///
/// [label] and [description] are written for a person, not a textbook — the
/// onboarding screen shows "desk job, little exercise", never "sedentary, 1.2".
enum ActivityLevel {
  sedentary(1.2, 'Not very active', 'Desk job, little or no exercise'),
  light(1.375, 'Lightly active', 'Light exercise one to three days a week'),
  moderate(1.55, 'Moderately active', 'Moderate exercise three to five days a week'),
  veryActive(1.725, 'Very active', 'Hard exercise six or seven days a week'),
  extraActive(1.9, 'Extremely active', 'Physical job, or training twice a day');

  const ActivityLevel(this.factor, this.label, this.description);

  final double factor;
  final String label;
  final String description;
}

/// Which way the user is trying to move.
///
/// Gaining and maintaining are first-class: the app is not loss-only, and no
/// screen may treat maintenance as an opt-out or a consolation.
enum GoalDirection { lose, maintain, gain }

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
    MealType.snack => 'Snack',
  };
}

/// Where a logged item's numbers came from.
///
/// Carried on every row. This is what makes the Sources screen possible, and
/// what lets the UI be honest about which figures are an estimate.
enum ItemSource {
  /// Proposed by the vision model and accepted by the user.
  ai,

  /// Looked up in the bundled food database.
  db,

  /// Reused from `food_cache` — a value the user previously accepted for this
  /// food, so a repeat meal reports the same numbers every time.
  cache,

  /// Typed in by hand.
  manual;

  String get label => switch (this) {
    ItemSource.ai => 'AI estimate',
    ItemSource.db => 'Food database',
    ItemSource.cache => 'Your saved value',
    ItemSource.manual => 'Entered by you',
  };

  /// Whether the UI should present this figure as an estimate rather than a
  /// looked-up fact.
  bool get isEstimate => this == ItemSource.ai;
}

/// The model's self-reported confidence in an item.
///
/// [low] drives the signature interaction: the item renders blurred and dimmed
/// with "tap to confirm portion" until the user commits to a portion.
enum Confidence { high, medium, low }
