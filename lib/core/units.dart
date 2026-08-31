/// Imperial display over metric storage.
///
/// Height and weight are held as centimetres and kilograms everywhere — the
/// database, the goal engine, the profile — and only ever converted at the
/// edge, for display and for reading a typed value back. Nothing downstream of
/// a screen knows imperial exists, which is what keeps Mifflin-St Jeor and the
/// BMI checks working on one set of units.
///
/// Someone who thinks in feet and inches almost always thinks in pounds, so the
/// two travel together under one preference rather than as separate switches.
library;

const cmPerInch = 2.54;
const inchesPerFoot = 12;
const kgPerPound = 0.45359237;

/// `177.8` -> `(feet: 5, inches: 10)`.
///
/// Rounds to the nearest whole inch, which is the precision anyone states a
/// height in. A round trip back through [feetInchesToCm] can therefore move the
/// stored value by up to a centimetre; that is well inside the noise of the
/// figure itself and far better than showing `5' 9.94"`.
({int feet, int inches}) cmToFeetInches(double cm) {
  final total = (cm / cmPerInch).round();
  return (feet: total ~/ inchesPerFoot, inches: total % inchesPerFoot);
}

double feetInchesToCm(int feet, int inches) =>
    (feet * inchesPerFoot + inches) * cmPerInch;

double kgToPounds(double kg) => kg / kgPerPound;

double poundsToKg(double pounds) => pounds * kgPerPound;

/// The height as a person would say it: `5'10"` or `178 cm`.
String formatHeight(double cm, {required bool imperial}) {
  if (!imperial) return '${cm.round()} cm';
  final (:feet, :inches) = cmToFeetInches(cm);
  return "$feet'$inches\"";
}

/// The weight as a person would say it: `172 lb` or `78 kg`.
String formatWeight(double kg, {required bool imperial}) =>
    imperial ? '${kgToPounds(kg).round()} lb' : '${kg.round()} kg';
