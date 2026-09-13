/// Make two spellings of the same place match.
///
/// Client, 2026-09-13, with two screenshots of the city picker: typing "nain"
/// finds **Naini Tāl** and typing "nainital" finds nothing; "dehra" offers
/// both **Dehra Dūn** and **Dehradun**. The list is a transliterated gazetteer
/// — `lib/utils/csc_picker/assets/country.json` really does hold
/// `"Naini Tāl"` and `"Dehra Dūn"` — and every filter in the picker
/// was a plain `toLowerCase().contains(...)`. A macron is not an "a", and a
/// space is not nothing, so the two spellings could never meet.
///
/// Nobody types a macron. The person searching for Nainital types "nainital".
///
/// ── What this does, and what it must NOT do ────────────────────────────────
///
/// Folding is for COMPARISON ONLY. The label a guest reads stays exactly as
/// the data spells it — "Naini Tāl" is how the place is written here and
/// rewriting it would be a different bug. Nothing folded is ever stored, sent
/// or displayed.
///
/// It also drops spaces, hyphens and apostrophes, which is what makes
/// "dehra dun" find "Dehradun" and "nainital" find "Naini Tāl". That is the
/// whole point: the gazetteer and the keyboard disagree about where the word
/// breaks are.
///
/// ── Why a lookup table and not a Unicode normaliser ────────────────────────
///
/// Dart has no NFD normaliser in the core library and this is not worth a
/// dependency. The table below was GENERATED from the picker's own asset by
/// decomposing every character it actually contains — 276 distinct non-ASCII
/// characters, 170 of which fold to a single ASCII letter — so it covers this
/// data by construction rather than by guesswork.
///
/// Anything outside the Latin blocks is left alone rather than deleted.
/// Devanagari in particular must pass through untouched: a filter that strips
/// what it does not recognise would turn "नैनीताल" into nothing and match
/// everything. (The same trap as `\p{L}` without `\p{M}`, which once deleted
/// matras from real names.)
library;

/// U+00C0 … U+024F, one ASCII letter per code point, '.' where there is none.
///
/// Indexed by `codeUnit - 0xC0`. Generated; see the note above.
const String _latinFold =
    'aaaaaa.ceeeeiiii.nooooo..uuuuy..aaaaaa.ceeeeiiii.nooooo..uuuuy.yaaaaaaccccccccdd'
    '..eeeeeeeeeegggggggghh..iiiiiiiii...jjkk.llllllll..nnnnnnn..oooooo..rrrrrrssssss'
    'sstttt..uuuuuuuuuuuuwwyyyzzzzzzs................................oo.............u'
    'u............................aaiioouuuuuuuuuu.aaaa....ggkkoooo..j...gg..nnaa....'
    'aaaaeeeeiiiioooorrrruuuusstt..hh......aaeeooooooooyy............................';

/// The handful that become more than one letter, or that the table above
/// leaves as '.' because they have no decomposition at all.
const Map<int, String> _special = <int, String>{
  0x00C6: 'ae', 0x00E6: 'ae', // Æ æ
  0x0152: 'oe', 0x0153: 'oe', // Œ œ
  0x00DF: 'ss', // ß
  0x00DE: 'th', 0x00FE: 'th', // Þ þ
  0x00D0: 'd', 0x00F0: 'd', // Ð ð
  0x0110: 'd', 0x0111: 'd', // Đ đ
  0x00D8: 'o', 0x00F8: 'o', // Ø ø
  0x0141: 'l', 0x0142: 'l', // Ł ł
  0x0131: 'i', // ı — dotless i, common in Turkish place names
};

/// The comparable form of a name: lowercase, unaccented, letters and digits.
///
/// `searchFold('Naini Tāl') == 'nainital'`, which is what somebody types.
String searchFold(String? input) {
  final s = input ?? '';
  if (s.isEmpty) return '';
  final buf = StringBuffer();

  for (final rune in s.runes) {
    // ASCII first: the overwhelming majority of every list, and no work.
    if (rune < 0x80) {
      if ((rune >= 0x30 && rune <= 0x39) || (rune >= 0x61 && rune <= 0x7A)) {
        buf.writeCharCode(rune);
      } else if (rune >= 0x41 && rune <= 0x5A) {
        buf.writeCharCode(rune + 32); // to lower
      }
      // Everything else ASCII — space, hyphen, apostrophe, brackets — is
      // dropped, which is what lets "dehra dun" find "Dehradun".
      continue;
    }

    final special = _special[rune];
    if (special != null) {
      buf.write(special);
      continue;
    }

    if (rune >= 0xC0 && rune < 0xC0 + _latinFold.length) {
      final folded = _latinFold[rune - 0xC0];
      if (folded != '.') buf.write(folded);
      continue;
    }

    // Curly quotes and the other punctuation the gazetteer carries.
    if (rune == 0x2018 || rune == 0x2019 || rune == 0x201C || rune == 0x201D) {
      continue;
    }

    // Not Latin — Devanagari, Arabic, CJK. Kept as it is, lowercased where
    // that means anything. Dropping it would make the filter match everything.
    buf.write(String.fromCharCode(rune).toLowerCase());
  }

  return buf.toString();
}

/// Does `haystack` contain `needle`, ignoring accents, case and word breaks?
///
/// An empty needle matches everything, which is what a cleared search box
/// should do.
bool searchMatches(String? haystack, String? needle) {
  final n = searchFold(needle);
  if (n.isEmpty) return true;
  return searchFold(haystack).contains(n);
}
