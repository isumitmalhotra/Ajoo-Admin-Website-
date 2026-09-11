import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A sheet that closes must not hand the keyboard back.
///
/// Step 3 of the wizard is several screens long and mixes number fields
/// (police / hospital / fire-station distance) with the photo grid. Closing
/// a bottom sheet restores focus to whatever held it before — the last
/// number field the host typed in — so the keyboard reopened, the form
/// scrolled up to reveal that field, and the host was thrown from the photo
/// grid back to "Hospital distance". Their next tap landed in it.
///
/// Driven on the device on 2026-09-11, listing a camp: tagging four photos
/// moved the page three times and wrote stray digits into two distance
/// fields ("129", "127"), and the first tap after an upload did the same.
void main() {
  final src = File(
    'lib/ui/screens_host/listing/listing_wizard_screen.dart',
  ).readAsStringSync();

  String body(String from, String to) {
    final i = src.indexOf(from);
    expect(i, greaterThan(-1), reason: 'could not find $from');
    final j = src.indexOf(to, i + from.length);
    return src.substring(i, j > i ? j : src.length);
  }

  test('the tag sheet drops focus on the way in and on the way out', () {
    final tag = body('Future<void> _tag(', 'Future<void> _pick(');
    expect(
      'unfocus()'.allMatches(tag).length,
      greaterThanOrEqualTo(2),
      reason: 'tagging a photo re-focuses the number field behind the sheet, '
          'which reopens the keyboard and scrolls the form away',
    );
    // Before the sheet opens...
    expect(tag.indexOf('unfocus()'), lessThan(tag.indexOf('showModalBottomSheet')));
    // ...and after it returns, before anything is saved.
    expect(tag.lastIndexOf('unfocus()'),
        lessThan(tag.indexOf('controller.setPhotoCategory')));
  });

  test('the photo picker and the describe sheet do the same', () {
    final pick = body('Future<void> _pick(', 'Future<List<String>?> _describePhotos(');
    expect('unfocus()'.allMatches(pick).length, greaterThanOrEqualTo(3),
        reason: 'the first keystroke after an upload went into a distance field');
    expect(pick.indexOf('unfocus()'), lessThan(pick.indexOf('pickMultiImage')));
    expect(pick.lastIndexOf('unfocus()'), lessThan(pick.indexOf('controller.uploadPhotos')));
  });
}
