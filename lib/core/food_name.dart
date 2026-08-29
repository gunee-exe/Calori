/// Food-name normalisation.
///
/// **This must produce byte-identical output to `normalise()` in
/// `tools/build_foods_db/normalise.py`.** The Python version writes
/// `foods.name_normalised` into the shipped database; this one computes the
/// value compared against it, both for the search query's prefix tier and for
/// `food_cache` lookups. A divergence does not throw — it just means the cache
/// never hits and the prefix tier never fires, silently, forever.
///
/// `test/core/food_name_test.dart` pins the two together with cases generated
/// from the Python implementation.
library;

/// Everything that is not a letter, a digit, or a combining mark.
///
/// `\p{M}` matters for the same reason it does in the FTS query builder:
/// Devanagari and most Indic scripts carry vowels as combining marks, and
/// treating them as separators shatters every Hindi food name into fragments.
final _punctuation = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

/// Latin letters that decompose to an ASCII base under NFKD.
///
/// Dart has no built-in Unicode normalisation, so the fold is table-driven.
/// This covers Latin-1 Supplement and Latin Extended-A, which is what the
/// European sources in the merge need — French (CIQUAL), Danish (Frida),
/// German, Spanish and Portuguese. Scripts outside Latin are left untouched,
/// which is correct: folding is only meaningful where the base letter exists.
const _fold = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'ă': 'a', 'ą': 'a',
  'ç': 'c', 'ć': 'c', 'ĉ': 'c', 'ċ': 'c', 'č': 'c',
  'ď': 'd',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e',
  'ę': 'e', 'ě': 'e',
  'ĝ': 'g', 'ğ': 'g', 'ġ': 'g', 'ģ': 'g',
  'ĥ': 'h',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ĩ': 'i', 'ī': 'i', 'ĭ': 'i',
  'į': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺ': 'l', 'ļ': 'l', 'ľ': 'l',
  'ñ': 'n', 'ń': 'n', 'ņ': 'n', 'ň': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ō': 'o',
  'ŏ': 'o', 'ő': 'o',
  'ŕ': 'r', 'ŗ': 'r', 'ř': 'r',
  'ś': 's', 'ŝ': 's', 'ş': 's', 'š': 's',
  'ţ': 't', 'ť': 't',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ũ': 'u', 'ū': 'u', 'ŭ': 'u',
  'ů': 'u', 'ű': 'u', 'ų': 'u',
  'ŵ': 'w',
  'ý': 'y', 'ÿ': 'y', 'ŷ': 'y',
  'ź': 'z', 'ż': 'z', 'ž': 'z',
  // Letters with no ASCII decomposition. Each carries a stroke, a bar, or is a
  // ligature — they are distinct letters, not a base plus a combining mark, so
  // Python's NFKD leaves them untouched and this table must too. Folding "ø" to
  // "o" here would put "Smørrebrød" in the database as "smorrebrod" and make it
  // unfindable. Listed explicitly rather than merely omitted, so the omission
  // reads as deliberate:
  //   đ ħ ı ł ø ŧ ß æ œ ð þ
};

/// Folds accents, matching Python's NFKD-then-drop-combining-marks.
String foldAccents(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_fold[char.toLowerCase()] == null
        ? char
        : (char == char.toLowerCase()
              ? _fold[char]!
              : _fold[char.toLowerCase()]!.toUpperCase()));
  }
  return buffer.toString();
}

/// The dedup and cache key for a food name.
///
/// fold accents -> lowercase -> drop punctuation -> collapse whitespace.
///
/// ```
/// normaliseFoodName('Crème brûlée')            => 'creme brulee'
/// normaliseFoodName('Rice, white, long-grain') => 'rice white long grain'
/// normaliseFoodName('2% milk')                 => '2 milk'
/// ```
///
/// Note there is no singularisation. It was tried in the Python builder and
/// removed: any rule short enough to be worth having turns "molasses" into
/// "molasse" and "couscous" into "couscou", and the exception list needed to
/// avoid that would have to be mirrored here exactly.
String normaliseFoodName(String name) {
  final folded = foldAccents(name).toLowerCase();
  return folded.replaceAll(_punctuation, ' ').trim();
}
