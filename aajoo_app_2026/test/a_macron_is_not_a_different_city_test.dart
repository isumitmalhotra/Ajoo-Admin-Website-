import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/search_fold.dart';

/// Typing "nainital" has to find "Naini Tāl".
///
/// Client, 2026-09-13, with two screenshots of the city picker: "nain" finds
/// **Naini Tāl**, "nainital" finds nothing, and "dehra" offers both **Dehra
/// Dūn** and **Dehradun**. The picker's list is a transliterated gazetteer —
/// its own asset really does hold `"Naini Tāl"` and `"Dehra Dūn"` —
/// and every filter in it was a plain `toLowerCase().contains(...)`.
///
/// A macron is not an "a" and a space is not nothing, so the spelling in the
/// data and the spelling on the keyboard could never meet. Nobody types a
/// macron.
void main() {
  group('the two spellings meet', () {
    test('nainital finds Naini Tal', () {
      expect(searchMatches('Naini Tāl', 'nainital'), isTrue);
      expect(searchMatches('Naini Tāl', 'naini tal'), isTrue);
      expect(searchMatches('Naini Tāl', 'nain'), isTrue,
          reason: 'the prefix that already worked must keep working');
    });

    test('dehradun finds Dehra Dun, and the plain spelling too', () {
      expect(searchMatches('Dehra Dūn', 'dehradun'), isTrue);
      expect(searchMatches('Dehradun', 'dehra dun'), isTrue);
      expect(searchMatches('Dehra Dūn', 'DEHRA'), isTrue);
    });

    test('the other accents this gazetteer actually carries', () {
      // The three commonest in the asset, by count.
      expect(searchMatches('Bhopāl', 'bhopal'), isTrue);
      expect(searchMatches('Kānpūr', 'kanpur'), isTrue);
      expect(searchMatches('Varānasi', 'varanasi'), isTrue);
      expect(searchMatches('Puducherry', 'pondicherry'), isFalse,
          reason: 'folding is about spelling, not about knowing old names');
    });

    test('punctuation and case are not word breaks', () {
      expect(searchMatches("Mahābāleshwar", 'mahabaleshwar'), isTrue);
      expect(searchMatches('Port Blair', 'portblair'), isTrue);
      expect(searchMatches("Sant’ Anna", 'santanna'), isTrue);
    });
  });

  group('what folding must NOT do', () {
    test('a script it does not know is kept, not deleted', () {
      // A filter that strips what it cannot fold turns a Devanagari name into
      // an empty string, and an empty needle matches EVERYTHING. The same trap
      // as a \\p{L} filter without \\p{M}, which once deleted matras from real
      // names in this codebase.
      expect(searchFold('नैनीताल'), isNotEmpty);
      expect(searchMatches('नैनीताल', 'nainital'), isFalse);
      expect(
          searchMatches('नैनीताल',
              'नैनी'),
          isTrue);
    });

    test('it does not make everything match everything', () {
      expect(searchMatches('Naini Tāl', 'mumbai'), isFalse);
      expect(searchMatches('Dehradun', 'delhi'), isFalse);
      expect(searchMatches('Goa', 'gurugram'), isFalse);
    });

    test('an empty search shows the whole list', () {
      expect(searchMatches('anything', ''), isTrue);
      expect(searchMatches('anything', null), isTrue);
      expect(searchMatches('anything', '   '), isTrue,
          reason: 'spaces fold away to nothing, and nothing matches all');
    });

    test('it survives the shapes a list can actually hold', () {
      expect(searchFold(null), '');
      expect(searchFold(''), '');
      expect(searchMatches(null, 'x'), isFalse);
      expect(searchMatches('', 'x'), isFalse);
    });
  });

  group('the fold itself', () {
    test('accents become their plain letter', () {
      expect(searchFold('āéîõū'), 'aeiou');
      expect(searchFold('ÀÉÎ'), 'aei');
    });

    test('the multi-letter ones expand', () {
      expect(searchFold('ß'), 'ss'); // ß
      expect(searchFold('æ'), 'ae'); // æ
      expect(searchFold('œ'), 'oe'); // œ
      expect(searchFold('ø'), 'o'); // ø — no decomposition at all
      expect(searchFold('ł'), 'l'); // ł
      expect(searchFold('ı'), 'i'); // ı, Turkish dotless i
    });

    test('digits survive, because some places have them', () {
      expect(searchFold('Sector 25'), 'sector25');
    });
  });
}
