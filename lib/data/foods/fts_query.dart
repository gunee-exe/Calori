/// Turns arbitrary user input into a safe FTS5 MATCH expression.
///
/// Kept free of Drift and Flutter imports so it can be unit-tested directly.
library;

/// Matches any run of characters that is not a letter, a digit, or a combining
/// mark. Splitting on this removes every FTS5 operator structurally, so none can
/// reach the query parser.
///
/// `\p{M}` is load-bearing, not decoration. In Devanagari and most Indic
/// scripts the vowel signs are combining marks rather than letters, so without
/// it "बिरयानी" tokenises to `"ब" "रय" "न"` — every Hindi and Marathi food name
/// shattered into unsearchable fragments, silently and with no error. The same
/// applies to Arabic and Urdu harakat, Thai vowel marks, and Hebrew niqqud.
final _separators = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

/// Builds a prefix-search FTS5 query from raw typed text.
///
/// ```
/// buildFtsQuery('chicken bir')   =>  '"chicken" "bir"*'
/// buildFtsQuery('chick-pea')     =>  '"chick" "pea"*'
/// buildFtsQuery('rice "OR" NOT') =>  '"rice" "OR" "NOT"*'
/// buildFtsQuery('   ')           =>  ''
/// ```
///
/// FTS5 has its own operator grammar — `AND OR NOT NEAR`, `*`, `^`, `:`, `"`
/// and parentheses. Passing raw input into `MATCH` is both a reliable way to
/// throw a syntax error on ordinary text (an apostrophe, a hyphen) and a
/// denial-of-service vector (a lone `*` scans the entire index).
///
/// The safe technique is to tokenise and quote, never to blocklist characters.
/// Quoting turns every token into a literal phrase, so `OR` and `NOT` are
/// searched for as words rather than obeyed as operators.
///
/// Returns an empty string when there is nothing searchable. **Callers must
/// check for that and skip the query** — an empty `MATCH` is a runtime error in
/// SQLite, not an empty result set.
String buildFtsQuery(String input) {
  final tokens = input
      .split(_separators)
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  if (tokens.isEmpty) return '';

  final buffer = StringBuffer();
  for (var i = 0; i < tokens.length; i++) {
    if (i > 0) buffer.write(' ');

    // SQLite's own guidance for embedding a string in a quoted FTS5 phrase:
    // double any interior quote, then wrap. Nothing survives the split above
    // that would need this, but it costs nothing and keeps the function correct
    // if the separator pattern is ever loosened.
    final token = tokens[i].replaceAll('"', '""');

    buffer
      ..write('"')
      ..write(token)
      ..write('"');

    // Prefix-match the final token only — that is the word still being typed.
    //
    // The asterisk MUST sit OUTSIDE the closing quote. `"chicken"*` is a prefix
    // query; `"chicken*"` is a phrase containing a literal asterisk, which the
    // unicode61 tokeniser strips, silently degrading to an exact-token match.
    // This is the single most common FTS5 bug.
    //
    // Prefixing every token instead would make each keystroke scan a huge
    // prefix range for words the user has already finished typing.
    if (i == tokens.length - 1) buffer.write('*');
  }

  return buffer.toString();
}
