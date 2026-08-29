/// Domain models for food and its macros.
///
/// Deliberately free of Drift: `domain` must not depend on `data`, so these are
/// plain Dart and the repository implementations map Drift rows onto them.
library;

/// A set of macros for some specific quantity of food.
///
/// Not per-100g — this is a resolved amount, ready to store on an entry item.
class Macros {
  const Macros({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  static const zero = Macros(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0);

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  Macros operator +(Macros other) => Macros(
    kcal: kcal + other.kcal,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
  );

  Macros scaled(double factor) => Macros(
    kcal: kcal * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
  );

  /// Energy implied by the macros under standard Atwater factors.
  ///
  /// Used to sanity-check imported data. It will not match [kcal] exactly —
  /// fibre, alcohol, polyols and food-specific factors all shift it — so
  /// compare with a wide tolerance or not at all.
  double get atwaterKcal => proteinG * 4 + carbsG * 4 + fatG * 9;
}

/// A named household portion, e.g. "1 cup" at 240 g.
class FoodPortion {
  const FoodPortion({
    required this.label,
    required this.grams,
    this.isDefault = false,
  });

  final String label;
  final double grams;
  final bool isDefault;
}

/// A food from the bundled database, with its per-100g macros.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.nameNormalised,
    required this.source,
    required this.per100g,
    this.localeHint,
    this.portions = const [],
  });

  final int id;
  final String name;
  final String nameNormalised;

  /// The dataset this row came from: `usda_sr`, `indb`, `cofid`, and so on.
  /// Surfaced as the badge on a search result and on the Sources screen.
  final String source;

  /// Macros per 100 grams. Everything else is derived from this.
  final Macros per100g;

  /// `IN`, `PK`, `GB`, … Used only to break ranking ties toward a regional
  /// match. Never used to filter results.
  final String? localeHint;

  /// Household portions, default first. May be empty, in which case the UI
  /// falls back to grams.
  final List<FoodPortion> portions;

  /// The portion to preselect, or null when only grams are available.
  FoodPortion? get defaultPortion {
    if (portions.isEmpty) return null;
    for (final p in portions) {
      if (p.isDefault) return p;
    }
    return portions.first;
  }

  /// Macros for an arbitrary weight.
  Macros macrosFor(double grams) => per100g.scaled(grams / 100);

  /// The short label shown on a search result badge.
  String get sourceLabel => switch (source) {
    'usda_sr' || 'usda_foundation' || 'usda_fndds' => 'USDA',
    'cofid' => 'CoFID',
    'ciqual' => 'CIQUAL',
    'cnf' => 'CNF',
    'frida' => 'Frida',
    'indb' => 'INDB',
    'pakistan_fct' => 'FCT-PK',
    _ => source.toUpperCase(),
  };
}

/// A nutrition value the user has already accepted for a food, reused so a
/// repeat meal reports the same numbers every time.
///
/// Populated from *accepted* values rather than proposed ones, so it converges
/// on the user's corrections rather than on the model's first guess.
class CachedFood {
  const CachedFood({
    required this.nameNormalised,
    required this.per100g,
    required this.lastUsedAt,
    required this.useCount,
  });

  final String nameNormalised;
  final Macros per100g;
  final DateTime lastUsedAt;
  final int useCount;

  Macros macrosFor(double grams) => per100g.scaled(grams / 100);
}
