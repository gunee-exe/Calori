/// Number and date formatting.
///
/// One rule runs through all of it: **never imply more precision than the
/// underlying estimate has.** A photo-derived calorie figure is accurate to
/// perhaps ±20%, so rendering it as "617.4 kcal" is a lie told in decimal
/// places. Values are rounded to whole numbers, and large ones are grouped.
library;

import 'package:intl/intl.dart';

import '../domain/models/enums.dart';

final _grouped = NumberFormat('#,##0');
final _oneDecimal = NumberFormat('0.#');

/// `1040` -> `"1,040"`.
String formatKcal(double value) => _grouped.format(value.round());

/// Grams, rounded to whole numbers. `56.7` -> `"57"`.
///
/// Sub-gram precision is noise at the scale this app works in, and it makes
/// the macro row jitter as a portion is adjusted.
String formatGrams(double value) => _grouped.format(value.round());

/// A portion multiplier: `0.5` -> `"0.5"`, `2.0` -> `"2"`.
String formatQuantity(double value) => _oneDecimal.format(value);

/// `20260826` -> `"Wednesday, 26 August"`.
String formatDayKeyLong(int dayKey) {
  final date = DateTime(dayKey ~/ 10000, (dayKey ~/ 100) % 100, dayKey % 100);
  return DateFormat('EEEE, d MMMM').format(date);
}

/// `20260826` -> `"26 August"`.
String formatDayKeyShort(int dayKey) {
  final date = DateTime(dayKey ~/ 10000, (dayKey ~/ 100) % 100, dayKey % 100);
  return DateFormat('d MMMM').format(date);
}

/// The meal a log at this time of day most likely belongs to.
///
/// A default, never a decision — the user can always change it. Boundaries are
/// deliberately generous at the edges: a 4pm snack is more likely a snack than
/// an early dinner, and food logged at 1am is far more likely to be a late
/// snack than tomorrow's breakfast.
MealType mealTypeForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  return switch (hour) {
    >= 5 && < 11 => MealType.breakfast,
    >= 11 && < 15 => MealType.lunch,
    >= 18 && < 22 => MealType.dinner,
    _ => MealType.snack,
  };
}
