import 'package:calori/data/foods/fts_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildFtsQuery', () {
    test('quotes each token and prefixes only the last', () {
      expect(buildFtsQuery('chicken bir'), '"chicken" "bir"*');
    });

    test('a single word is a prefix query', () {
      expect(buildFtsQuery('biry'), '"biry"*');
    });

    test('the asterisk sits outside the closing quote', () {
      // `"chicken"*` is a prefix query. `"chicken*"` is a phrase containing a
      // literal asterisk, which the unicode61 tokeniser strips — silently
      // degrading to an exact-token match. Getting this backwards is the most
      // common FTS5 bug and would break as-you-type search without any error.
      final q = buildFtsQuery('chicken');
      expect(q.endsWith('"*'), isTrue);
      expect(q.contains('*"'), isFalse);
    });

    test('splits on punctuation rather than passing it through', () {
      expect(buildFtsQuery('chick-pea'), '"chick" "pea"*');
      expect(buildFtsQuery("mother's day cake"), '"mother" "s" "day" "cake"*');
    });

    group('FTS5 operators are neutralised', () {
      test('boolean keywords become literal search terms', () {
        // Quoted, these are words to find, not operators to obey.
        expect(buildFtsQuery('rice OR NOT'), '"rice" "OR" "NOT"*');
      });

      test('a bare asterisk yields nothing to search', () {
        // Left unescaped this would scan the entire index — a denial of service
        // from a single keystroke.
        expect(buildFtsQuery('*'), '');
      });

      test('column filters and anchors cannot reach the parser', () {
        expect(buildFtsQuery('name:rice'), '"name" "rice"*');
        expect(buildFtsQuery('^rice'), '"rice"*');
      });

      test('unbalanced quotes do not produce a syntax error', () {
        expect(buildFtsQuery('rice"'), '"rice"*');
        expect(buildFtsQuery('"'), '');
      });

      test('parentheses and NEAR are inert', () {
        expect(buildFtsQuery('(rice NEAR curry)'), '"rice" "NEAR" "curry"*');
      });
    });

    group('empty input', () {
      // Callers must skip the query on an empty string: an empty MATCH is a
      // runtime error in SQLite, not an empty result set.
      test('blank and whitespace-only input yield an empty query', () {
        expect(buildFtsQuery(''), '');
        expect(buildFtsQuery('   '), '');
        expect(buildFtsQuery('\t\n'), '');
      });

      test('punctuation-only input yields an empty query', () {
        expect(buildFtsQuery('---'), '');
        expect(buildFtsQuery('!@#\$%^&()'), '');
      });
    });

    group('non-Latin scripts survive tokenisation', () {
      test('Urdu is kept as searchable tokens', () {
        expect(buildFtsQuery('چکن بریانی'), '"چکن" "بریانی"*');
      });

      test('Devanagari is kept as searchable tokens', () {
        expect(buildFtsQuery('चिकन बिरयानी'), '"चिकन" "बिरयानी"*');
      });

      test('accented Latin passes through for the tokeniser to fold', () {
        // remove_diacritics 2 on the FTS side is what makes this match
        // "creme brulee"; the query builder must not strip the accents itself.
        expect(buildFtsQuery('crème brûlée'), '"crème" "brûlée"*');
      });

      test('digits are searchable', () {
        expect(buildFtsQuery('2% milk'), '"2" "milk"*');
      });
    });
  });
}
